import 'package:appwrite/appwrite.dart';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get/get.dart';
import 'dart:convert';
import '../models/feed_post.dart';
import '../models/post_comment.dart';
import '../models/post_like.dart';
import '../models/post_repost.dart';
import '../../bookmarks/models/bookmark.dart';

class FeedService {
  final Databases databases;
  final Storage storage;
  final Functions functions;
  final String databaseId;
  final String postsCollectionId;
  final String commentsCollectionId;
  final String likesCollectionId;
  final String repostsCollectionId;
  final String bookmarksCollectionId;
  final String linkMetadataFunctionId;
  final Connectivity connectivity;
  final Box postsBox = Hive.box('posts');
  final Box commentsBox = Hive.box('comments');
  final Box bookmarksBox = Hive.box('bookmarks');
  final Box queueBox = Hive.box('action_queue');
  final Box postQueueBox = Hive.box('post_queue');

  FeedService({
    required this.databases,
    required this.storage,
    required this.functions,
    required this.databaseId,
    required this.postsCollectionId,
    required this.commentsCollectionId,
    required this.likesCollectionId,
    required this.repostsCollectionId,
    required this.bookmarksCollectionId,
    required this.connectivity,
    required this.linkMetadataFunctionId,
  }) {
    connectivity.onConnectivityChanged.listen((result) async {
      if (result != ConnectivityResult.none) {
        await syncQueuedActions();
      }
    });
  }

  Future<List<FeedPost>> getPosts(String roomId,
      {List<String> blockedIds = const []}) async {
    try {
      final queries = [
        Query.equal('room_id', roomId),
        Query.orderDesc('\$createdAt'),
      ];
      for (final id in blockedIds) {
        queries.add(Query.notEqual('user_id', id));
      }
      final res = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: postsCollectionId,
        queries: queries,
      );
      final posts = res.documents
          .map((e) => FeedPost.fromJson(e.data))
          .where((p) => !p.isDeleted && !blockedIds.contains(p.userId))
          .toList();
      final cache = posts
          .map((e) => {...e.toJson(), '_cachedAt': DateTime.now().toIso8601String()})
          .toList();
      await postsBox.put('posts_$roomId', cache);
      return posts;
    } catch (_) {
      final cached = postsBox.get('posts_$roomId', defaultValue: []) as List;
      final expiry = DateTime.now().subtract(const Duration(days: 30));
      return cached
          .where((e) {
            final ts = DateTime.tryParse(e['_cachedAt'] ?? '');
            return ts == null || ts.isAfter(expiry);
          })
          .map((e) => FeedPost.fromJson(Map<String, dynamic>.from(e)))
          .where((p) => !p.isDeleted && !blockedIds.contains(p.userId))
          .toList();
    }
  }

  Future<List<FeedPost>> getPostsByHashtag(String tag) async {
    final res = await databases.listDocuments(
      databaseId: databaseId,
      collectionId: postsCollectionId,
      queries: [
        Query.search('hashtags', tag),
        Query.orderDesc('\$createdAt'),
      ],
    );
    return res.documents
        .map((e) => FeedPost.fromJson(e.data))
        .where((p) => !p.isDeleted)
        .toList();
  }

  Future<void> createPost(FeedPost post) async {
    try {
      await databases.createDocument(
        databaseId: databaseId,
        collectionId: postsCollectionId,
        documentId: ID.unique(),
        data: post.toJson(),
      );
    } catch (_) {
      await queueBox.add({
        'action': 'post',
        'data': post.toJson(),
        '_cachedAt': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<String> uploadImage(File image) async {
    final compressed = await FlutterImageCompress.compressAndGetFile(
      image.path,
      '${image.path}_compressed.jpg',
      quality: 80,
    );
    final result = await storage.createFile(
      bucketId: 'post_images',
      fileId: ID.unique(),
      file: InputFile.fromPath(path: compressed!.path),
    );
    return '${storage.client.endPoint}/storage/buckets/post_images/files/${result.\$id}/view?project=${storage.client.config['project']}';
  }

  Future<void> createPostWithImage(
    String userId,
    String username,
    String content,
    String? roomId,
    File image,
    {List<String> hashtags = const [], List<String> mentions = const []},
  ) async {
    try {
      final imageUrl = await uploadImage(image);
      final post = FeedPost(
        id: DateTime.now().toIso8601String(),
        roomId: roomId ?? '',
        userId: userId,
        username: username,
        content: content,
        mediaUrls: [imageUrl],
        hashtags: hashtags,
        mentions: mentions,
      );
      await createPost(post);
    } catch (_) {
      await postQueueBox.add({
        'action': 'post_with_image',
        'user_id': userId,
        'username': username,
        'content': content,
        'room_id': roomId,
        'image_path': image.path,
        'hashtags': hashtags,
        'mentions': mentions,
        '_cachedAt': DateTime.now().toIso8601String(),
      });
      Get.snackbar('Offline', 'Image post queued for syncing');
    }
  }

  Future<Map<String, dynamic>> fetchLinkMetadata(String url) async {
    final result = await functions.createExecution(
      functionId: linkMetadataFunctionId,
      body: jsonEncode({'url': url}),
    );
    return jsonDecode(result.responseBody) as Map<String, dynamic>;
  }

  Future<void> createPostWithLink(
    String userId,
    String username,
    String content,
    String? roomId,
    String linkUrl,
    {List<String> hashtags = const [], List<String> mentions = const []},
  ) async {
    try {
      final metadata = await fetchLinkMetadata(linkUrl);
      final post = FeedPost(
        id: DateTime.now().toIso8601String(),
        roomId: roomId ?? '',
        userId: userId,
        username: username,
        content: content,
        linkUrl: linkUrl,
        linkMetadata: metadata,
        hashtags: hashtags,
        mentions: mentions,
      );
      await createPost(post);
    } catch (_) {
      await queueBox.add({
        'action': 'post_with_link',
        'user_id': userId,
        'username': username,
        'content': content,
        'room_id': roomId,
        'link_url': linkUrl,
        'hashtags': hashtags,
        'mentions': mentions,
        '_cachedAt': DateTime.now().toIso8601String(),
      });
      Get.snackbar('Offline', 'Link post queued for syncing');
    }
  }

  Future<List<PostComment>> getComments(String postId) async {
    try {
      final res = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: commentsCollectionId,
        queries: [
          Query.equal('post_id', postId),
          Query.orderAsc('\$createdAt'),
        ],
      );
      final comments = res.documents
          .map((e) => PostComment.fromJson(e.data))
          .where((c) => !c.isDeleted)
          .toList();
      final cache = comments
          .map((e) => {...e.toJson(), '_cachedAt': DateTime.now().toIso8601String()})
          .toList();
      await commentsBox.put('comments_$postId', cache);
      return comments;
    } catch (_) {
      final cached = commentsBox.get('comments_$postId', defaultValue: []) as List;
      final expiry = DateTime.now().subtract(const Duration(days: 30));
      return cached
          .where((e) {
            final ts = DateTime.tryParse(e['_cachedAt'] ?? '');
            return ts == null || ts.isAfter(expiry);
          })
          .map((e) => PostComment.fromJson(Map<String, dynamic>.from(e)))
          .where((c) => !c.isDeleted)
          .toList();
    }
  }

  Future<void> createComment(PostComment comment) async {
    try {
      await databases.createDocument(
        databaseId: databaseId,
        collectionId: commentsCollectionId,
        documentId: ID.unique(),
        data: comment.toJson(),
      );
    } catch (_) {
      await commentsBox.put(
        comment.id,
        {...comment.toJson(), '_cachedAt': DateTime.now().toIso8601String()},
      );
      await queueBox.add({
        'action': 'comment',
        'data': comment.toJson(),
        '_cachedAt': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> createLike(Map<String, dynamic> like) async {
    try {
      await databases.createDocument(
        databaseId: databaseId,
        collectionId: likesCollectionId,
        documentId: ID.unique(),
        data: like,
      );
    } catch (_) {
      await queueBox.add({
        'action': 'like',
        'data': like,
        '_cachedAt': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<String?> createRepost(Map<String, dynamic> repost) async {
    try {
      final doc = await databases.createDocument(
        databaseId: databaseId,
        collectionId: repostsCollectionId,
        documentId: ID.unique(),
        data: repost,
      );
      return doc.$id;
    } catch (_) {
      await queueBox.add({
        'action': 'repost',
        'data': repost,
        '_cachedAt': DateTime.now().toIso8601String(),
      });
      return null;
    }
  }

  Future<void> deleteRepost(String repostId) async {
    await databases.deleteDocument(
      databaseId: databaseId,
      collectionId: repostsCollectionId,
      documentId: repostId,
    );
  }

  Future<void> saveHashtags(List<String> tags) async {
    for (final tag in tags) {
      try {
        final existing = await databases.listDocuments(
          databaseId: databaseId,
          collectionId: 'hashtags',
          queries: [Query.equal('hashtag', tag)],
        );
        if (existing.documents.isEmpty) {
          await databases.createDocument(
            databaseId: databaseId,
            collectionId: 'hashtags',
            documentId: ID.unique(),
            data: {
              'hashtag': tag,
              'usage_count': 1,
              'last_used_at': DateTime.now().toIso8601String(),
            },
          );
        } else {
          final doc = existing.documents.first;
          final count = (doc.data['usage_count'] ?? 0) as int;
          await databases.updateDocument(
            databaseId: databaseId,
            collectionId: 'hashtags',
            documentId: doc.$id,
            data: {
              'usage_count': count + 1,
              'last_used_at': DateTime.now().toIso8601String(),
            },
          );
        }
      } catch (_) {
        await queueBox.add({
          'action': 'hashtag',
          'data': tag,
          '_cachedAt': DateTime.now().toIso8601String(),
        });
      }
    }
  }

  Future<PostLike?> getUserLike(String itemId, String userId) async {
    final res = await databases.listDocuments(
      databaseId: databaseId,
      collectionId: likesCollectionId,
      queries: [
        Query.equal('item_id', itemId),
        Query.equal('user_id', userId),
      ],
    );
    if (res.documents.isEmpty) return null;
    return PostLike.fromJson(res.documents.first.data);
  }

  Future<void> deleteLike(String likeId) async {
    await databases.deleteDocument(
      databaseId: databaseId,
      collectionId: likesCollectionId,
      documentId: likeId,
    );
  }

  Future<void> likeComment(String commentId, String userId) async {
    await createLike({
      'item_id': commentId,
      'item_type': 'comment',
      'user_id': userId,
    });
  }

  Future<void> unlikeComment(String likeId) async {
    await deleteLike(likeId);
  }

  Future<void> likeRepost(String repostId, String userId) async {
    await createLike({
      'item_id': repostId,
      'item_type': 'repost',
      'user_id': userId,
    });
  }

  Future<void> unlikeRepost(String likeId) async {
    await deleteLike(likeId);
  }

  Future<PostRepost?> getUserRepost(String postId, String userId) async {
    final res = await databases.listDocuments(
      databaseId: databaseId,
      collectionId: repostsCollectionId,
      queries: [
        Query.equal('post_id', postId),
        Query.equal('user_id', userId),
      ],
    );
    if (res.documents.isEmpty) return null;
    return PostRepost.fromJson(res.documents.first.data);
  }

  Future<void> editPost(
    String postId,
    String content,
    List<String> hashtags,
    List<String> mentions,
  ) async {
    try {
      final doc = await databases.getDocument(
        databaseId: databaseId,
        collectionId: postsCollectionId,
        documentId: postId,
      );
      final createdAtStr = doc.data['\$createdAt'] ?? doc.data['createdAt'];
      final createdAt = createdAtStr != null
          ? DateTime.parse(createdAtStr)
          : DateTime.now();
      if (DateTime.now().difference(createdAt).inMinutes > 30) {
        throw Exception('Edit window expired');
      }
      await databases.updateDocument(
        databaseId: databaseId,
        collectionId: postsCollectionId,
        documentId: postId,
        data: {
          'content': content,
          'hashtags': hashtags,
          'mentions': mentions,
          'is_edited': true,
          'edited_at': DateTime.now().toIso8601String(),
        },
      );

      for (final key in postsBox.keys) {
        final cached = postsBox.get(key, defaultValue: []) as List;
        final index = cached.indexWhere((p) => p['id'] == postId || p['\$id'] == postId);
        if (index != -1) {
          cached[index] = {
            ...cached[index],
            'content': content,
            'hashtags': hashtags,
            'mentions': mentions,
            'is_edited': true,
            'edited_at': DateTime.now().toIso8601String(),
          };
          await postsBox.put(key, cached);
        }
      }
    } catch (e) {
      throw Exception('Failed to edit post: $e');
    }
  }

  Future<void> syncQueuedActions() async {
    final expiry = DateTime.now().subtract(const Duration(days: 30));
    final keys = queueBox.keys.toList();
    for (final key in keys) {
      final Map item = queueBox.get(key);
      final ts = DateTime.tryParse(item['_cachedAt'] ?? '');
      if (ts != null && ts.isBefore(expiry)) {
        await queueBox.delete(key);
        continue;
      }
      try {
        switch (item['action']) {
          case 'like':
            await createLike(Map<String, dynamic>.from(item['data']));
            break;
          case 'repost':
            await createRepost(Map<String, dynamic>.from(item['data']));
            break;
          case 'bookmark':
            final data = Map<String, dynamic>.from(item['data']);
            await bookmarkPost(data['user_id'], data['post_id']);
            break;
          case 'comment':
            await createComment(PostComment.fromJson(
                Map<String, dynamic>.from(item['data'])));
            break;
          case 'post':
            await createPost(FeedPost.fromJson(
                Map<String, dynamic>.from(item['data'])));
            break;
          case 'post_with_link':
            await createPostWithLink(
              item['user_id'],
              item['username'],
              item['content'],
              item['room_id'],
              item['link_url'],
              hashtags: (item['hashtags'] as List?)?.cast<String>() ?? const [],
              mentions: (item['mentions'] as List?)?.cast<String>() ?? const [],
            );
            break;
          case 'hashtag':
            await saveHashtags([item['data'] as String]);
            break;
          case 'follow':
            await createFollow(Map<String, dynamic>.from(item['data']));
            break;
        }
        await queueBox.delete(key);
      } catch (_) {}
    }

    final imageKeys = postQueueBox.keys.toList();
    for (final key in imageKeys) {
      final Map item = postQueueBox.get(key);
      final ts = DateTime.tryParse(item['_cachedAt'] ?? '');
      if (ts != null && ts.isBefore(expiry)) {
        await postQueueBox.delete(key);
        continue;
      }
      try {
        if (item['action'] == 'post_with_image') {
          final file = File(item['image_path']);
          await createPostWithImage(
            item['user_id'],
            item['username'],
            item['content'],
            item['room_id'],
            file,
            hashtags: (item['hashtags'] as List?)?.cast<String>() ?? const [],
            mentions: (item['mentions'] as List?)?.cast<String>() ?? const [],
          );
        }
        await postQueueBox.delete(key);
      } catch (_) {}
    }
  }

  Future<void> bookmarkPost(String userId, String postId) async {
    try {
      await databases.createDocument(
        databaseId: databaseId,
        collectionId: bookmarksCollectionId,
        documentId: ID.unique(),
        data: {
          'user_id': userId,
          'post_id': postId,
          'created_at': DateTime.now().toIso8601String(),
        },
      );
    } catch (_) {
      await queueBox.add({
        'action': 'bookmark',
        'data': {'user_id': userId, 'post_id': postId},
        '_cachedAt': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> removeBookmark(String bookmarkId) async {
    await databases.deleteDocument(
      databaseId: databaseId,
      collectionId: bookmarksCollectionId,
      documentId: bookmarkId,
    );
  }

  Future<void> deletePost(String postId) async {
    try {
      await databases.updateDocument(
        databaseId: databaseId,
        collectionId: postsCollectionId,
        documentId: postId,
        data: {'is_deleted': true},
      );
      for (final key in postsBox.keys) {
        final cached = postsBox.get(key, defaultValue: []) as List;
        final index = cached.indexWhere(
          (p) => p['id'] == postId || p['\$id'] == postId,
        );
        if (index != -1) {
          cached[index] = {...cached[index], 'is_deleted': true};
          await postsBox.put(key, cached);
        }
      }
    } catch (e) {
      throw Exception('Failed to delete post: $e');
    }
  }

  Future<void> deleteComment(String commentId) async {
    try {
      await databases.updateDocument(
        databaseId: databaseId,
        collectionId: commentsCollectionId,
        documentId: commentId,
        data: {'is_deleted': true},
      );
      for (final key in commentsBox.keys) {
        final cached = commentsBox.get(key, defaultValue: []) as List;
        final index = cached.indexWhere(
          (c) => c['id'] == commentId || c['\$id'] == commentId,
        );
        if (index != -1) {
          cached[index] = {...cached[index], 'is_deleted': true};
          await commentsBox.put(key, cached);
        }
      }
    } catch (e) {
      throw Exception('Failed to delete comment: $e');
    }
  }

  Future<Bookmark?> getUserBookmark(String postId, String userId) async {
    final res = await databases.listDocuments(
      databaseId: databaseId,
      collectionId: bookmarksCollectionId,
      queries: [
        Query.equal('post_id', postId),
        Query.equal('user_id', userId),
      ],
    );
    if (res.documents.isEmpty) return null;
    return Bookmark.fromJson(res.documents.first.data);
  }

  Future<List<BookmarkedPost>> listBookmarks(String userId) async {
    try {
      final res = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: bookmarksCollectionId,
        queries: [
          Query.equal('user_id', userId),
          Query.orderDesc('created_at'),
        ],
      );
      final items = <BookmarkedPost>[];
      for (final doc in res.documents) {
        final post = await databases.getDocument(
          databaseId: databaseId,
          collectionId: postsCollectionId,
          documentId: doc.data['post_id'],
        );
        items.add(
          BookmarkedPost(
            bookmark: Bookmark.fromJson(doc.data),
            post: FeedPost.fromJson(post.data),
          ),
        );
      }
      await bookmarksBox.put(
        'bookmarks_$userId',
        items
            .map((e) => {
                  ...e.toMap(),
                  '_cachedAt': DateTime.now().toIso8601String(),
                })
            .toList(),
      );
      return items;
    } catch (_) {
      final cached =
          bookmarksBox.get('bookmarks_$userId', defaultValue: []) as List;
      final expiry = DateTime.now().subtract(const Duration(days: 30));
      return cached
          .where((e) {
            final ts = DateTime.tryParse(e['_cachedAt'] ?? '');
            return ts == null || ts.isAfter(expiry);
          })
          .map((e) => BookmarkedPost.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    }
  }

  Future<void> createFollow(Map<String, dynamic> follow) async {
    try {
      await databases.createDocument(
        databaseId: databaseId,
        collectionId: 'follows',
        documentId: ID.unique(),
        data: follow,
      );
    } catch (_) {
      await queueBox.add({
        'action': 'follow',
        'data': follow,
        '_cachedAt': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<List<FeedPost>> fetchSortedPosts(String sortType, {String? roomId}) async {
    final queries = <String>[Query.limit(20)];
    if (roomId != null) {
      queries.add(Query.equal('room_id', roomId));
    }
    switch (sortType) {
      case 'chronological':
      case 'most-recent':
        queries.add(Query.orderDesc('\$createdAt'));
        break;
      case 'most-commented':
        queries.add(Query.orderDesc('comment_count'));
        break;
      case 'most-liked':
        queries.add(Query.orderDesc('like_count'));
        break;
    }
    final key = 'posts_${sortType}_${roomId ?? 'home'}';
    try {
      final result = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: postsCollectionId,
        queries: queries,
      );
      final posts =
          result.documents.map((e) => FeedPost.fromJson(e.data)).toList();
      final cache = posts
          .map((e) => {...e.toJson(), '_cachedAt': DateTime.now().toIso8601String()})
          .toList();
      await postsBox.put(key, cache);
      return posts;
    } catch (_) {
      final cached = postsBox.get(key, defaultValue: []) as List;
      return cached
          .map((e) => FeedPost.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
  }

  Future<String> sharePost(String postId) async {
    try {
      await functions.createExecution(
        functionId: 'increment_share_count',
        data: jsonEncode({'post_id': postId}),
      );
      for (final key in postsBox.keys) {
        final cached = postsBox.get(key, defaultValue: []) as List;
        final index = cached.indexWhere(
          (p) => p['id'] == postId || p['\$id'] == postId,
        );
        if (index != -1) {
          final count = (cached[index]['share_count'] ?? 0) as int;
          cached[index] = {
            ...cached[index],
            'share_count': count + 1,
          };
          await postsBox.put(key, cached);
        }
      }
      return 'https://your-app.com/post/$postId';
    } catch (e) {
      throw Exception('Failed to share post: $e');
    }
  }
}
