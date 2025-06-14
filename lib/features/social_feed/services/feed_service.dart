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
import '../../notifications/services/notification_service.dart';
import '../controllers/comments_controller.dart';

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
  final Box hashtagsBox = Hive.box('hashtags');
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
    connectivity.onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      if (results.any((r) => r != ConnectivityResult.none)) {
        syncQueuedActions();
      }
    });
  }

  Future<void> _addToBoxWithLimit(Box box, Map<String, dynamic> data) async {
    if (box.length >= 50) {
      final firstKey = box.keys.first;
      await box.delete(firstKey);
    }
    await box.add(data);
  }

  List<String> _limitHashtags(List<String> tags) =>
      tags.length > 10 ? tags.sublist(0, 10) : tags;

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
          .map((e) =>
              {...e.toJson(), '_cachedAt': DateTime.now().toIso8601String()})
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
    final limited = _limitHashtags(post.hashtags);
    final toSave = limited.length == post.hashtags.length
        ? post
        : FeedPost(
            id: post.id,
            roomId: post.roomId,
            userId: post.userId,
            username: post.username,
            userAvatar: post.userAvatar,
            content: post.content,
            mediaUrls: post.mediaUrls,
            pollId: post.pollId,
            linkUrl: post.linkUrl,
            linkMetadata: post.linkMetadata,
            likeCount: post.likeCount,
            commentCount: post.commentCount,
            repostCount: post.repostCount,
            shareCount: post.shareCount,
            hashtags: limited,
            mentions: post.mentions,
            isEdited: post.isEdited,
            isDeleted: post.isDeleted,
            editedAt: post.editedAt,
          );
    try {
      await databases.createDocument(
        databaseId: databaseId,
        collectionId: postsCollectionId,
        documentId: ID.unique(),
        data: toSave.toJson(),
      );
    } catch (_) {
      await _addToBoxWithLimit(queueBox, {
        'action': 'post',
        'data': toSave.toJson(),
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
    return '${storage.client.endPoint}/storage/buckets/post_images/files/${result.$id}/view?project=${storage.client.config['project']}';
  }

  Future<void> createPostWithImage(
    String userId,
    String username,
    String content,
    String? roomId,
    File image, {
    List<String> hashtags = const [],
    List<String> mentions = const [],
  }) async {
    final limited = _limitHashtags(hashtags);
    try {
      final imageUrl = await uploadImage(image);
      final post = FeedPost(
        id: DateTime.now().toIso8601String(),
        roomId: roomId ?? '',
        userId: userId,
        username: username,
        content: content,
        mediaUrls: [imageUrl],
        hashtags: limited,
        mentions: mentions,
      );
      await createPost(post);
    } catch (_) {
      await _addToBoxWithLimit(postQueueBox, {
        'action': 'post_with_image',
        'user_id': userId,
        'username': username,
        'content': content,
        'room_id': roomId,
        'image_path': image.path,
        'hashtags': limited,
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
    String linkUrl, {
    List<String> hashtags = const [],
    List<String> mentions = const [],
  }) async {
    final limited = _limitHashtags(hashtags);
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
        hashtags: limited,
        mentions: mentions,
      );
      await createPost(post);
    } catch (_) {
      await _addToBoxWithLimit(queueBox, {
        'action': 'post_with_link',
        'user_id': userId,
        'username': username,
        'content': content,
        'room_id': roomId,
        'link_url': linkUrl,
        'hashtags': limited,
        'mentions': mentions,
        '_cachedAt': DateTime.now().toIso8601String(),
      });
      Get.snackbar('Offline', 'Link post queued for syncing');
    }
  }

  Future<List<PostComment>> getComments(
    String postId, {
    int limit = 20,
    String? cursor,
  }) async {
    try {
      final queries = [
        Query.equal('post_id', postId),
        Query.orderAsc('\$createdAt'),
        Query.limit(limit),
      ];
      if (cursor != null) queries.add(Query.cursorAfter(cursor));
      final res = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: commentsCollectionId,
        queries: queries,
      );
      final comments = res.documents
          .map((e) => PostComment.fromJson(e.data))
          .where((c) => !c.isDeleted)
          .toList();
      final cacheKey = 'comments_$postId';
      final existing =
          (commentsBox.get(cacheKey, defaultValue: []) as List).cast<dynamic>();
      final cache = comments
          .map((e) =>
              {...e.toJson(), '_cachedAt': DateTime.now().toIso8601String()})
          .toList();
      await commentsBox.put(
        cacheKey,
        cursor == null ? cache : [...existing, ...cache],
      );
      return comments;
    } catch (_) {
      final listKey = 'comments_$postId';
      final cachedList = (commentsBox.get(listKey, defaultValue: []) as List)
          .map((e) => Map<String, dynamic>.from(e));
      final merged = <String, Map<String, dynamic>>{};
      for (final item in cachedList) {
        final id = item['id'] ?? item['\$id'];
        if (id != null) merged[id] = item;
      }
      for (final key in commentsBox.keys) {
        if (key.toString().startsWith('comments_')) continue;
        final data = commentsBox.get(key);
        if (data is Map && data['post_id'] == postId) {
          final id = data['id'] ?? data['\$id'];
          if (id != null) merged[id] = Map<String, dynamic>.from(data);
        }
      }
      final expiry = DateTime.now().subtract(const Duration(days: 30));
      var list = merged.values
          .where((e) {
            final ts = DateTime.tryParse(e['_cachedAt'] ?? '');
            return ts == null || ts.isAfter(expiry);
          })
          .map(PostComment.fromJson)
          .where((c) => !c.isDeleted)
          .toList();
      if (cursor != null) {
        final index = list.indexWhere((c) => c.id == cursor);
        if (index != -1) list = list.sublist(index + 1);
      }
      return list.take(limit).toList();
    }
  }

  Future<String?> createComment(PostComment comment) async {
    String? id;
    try {
      final doc = await databases.createDocument(
        databaseId: databaseId,
        collectionId: commentsCollectionId,
        documentId: ID.unique(),
        data: comment.toJson(),
      );
      id = doc.data['\$id'] ?? doc.data['id'];
      await functions.createExecution(
        functionId: 'increment_comment_count',
        body: jsonEncode({'post_id': comment.postId}),
      );
      if (comment.parentId != null) {
        await functions.createExecution(
          functionId: 'increment_reply_count',
          body: jsonEncode({'comment_id': comment.parentId}),
        );
      }

      if (Get.isRegistered<NotificationService>()) {
        try {
          final post = await databases.getDocument(
            databaseId: databaseId,
            collectionId: postsCollectionId,
            documentId: comment.postId,
          );
          final ownerId = post.data['user_id'];
          if (ownerId != comment.userId) {
            await Get.find<NotificationService>().createNotification(
              ownerId,
              comment.userId,
              'comment',
              itemId: comment.postId,
              itemType: 'post',
            );
          }
        } catch (_) {}
      }
    } catch (_) {
      await commentsBox.put(
        comment.id,
        {...comment.toJson(), '_cachedAt': DateTime.now().toIso8601String()},
      );
      final listKey = 'comments_${comment.postId}';
      final current =
          (commentsBox.get(listKey, defaultValue: []) as List).cast<dynamic>();
      current.add(
          {...comment.toJson(), '_cachedAt': DateTime.now().toIso8601String()});
      await commentsBox.put(listKey, current);
      await _addToBoxWithLimit(queueBox, {
        'action': 'comment',
        'data': comment.toJson(),
        '_cachedAt': DateTime.now().toIso8601String(),
      });
    }

    for (final key in postsBox.keys) {
      final cached = postsBox.get(key, defaultValue: []) as List;
      final index = cached.indexWhere(
        (p) => p['id'] == comment.postId || p['\$id'] == comment.postId,
      );
      if (index != -1) {
        final count = (cached[index]['comment_count'] ?? 0) as int;
        cached[index] = {
          ...cached[index],
          'comment_count': count + 1,
        };
        await postsBox.put(key, cached);
      }
    }

    if (comment.parentId != null) {
      for (final key in commentsBox.keys) {
        final cached = commentsBox.get(key, defaultValue: []) as List;
        final index = cached.indexWhere(
          (c) => c['id'] == comment.parentId || c['\$id'] == comment.parentId,
        );
        if (index != -1) {
          final count = (cached[index]['reply_count'] ?? 0) as int;
          cached[index] = {
            ...cached[index],
            'reply_count': count + 1,
          };
          await commentsBox.put(key, cached);
        }
      }
      final parent = commentsBox.get(comment.parentId);
      if (parent is Map) {
        final count = (parent['reply_count'] ?? 0) as int;
        await commentsBox.put(
          comment.parentId,
          {...parent, 'reply_count': count + 1},
        );
      }
    }

    return id;
  }

  Future<void> createLike(Map<String, dynamic> like) async {
    try {
      await databases.createDocument(
        databaseId: databaseId,
        collectionId: likesCollectionId,
        documentId: ID.unique(),
        data: like,
      );
      if (like['item_type'] == 'comment') {
        await functions.createExecution(
          functionId: 'increment_comment_like_count',
          body: jsonEncode({'comment_id': like['item_id']}),
        );
      } else {
        await functions.createExecution(
          functionId: 'increment_like_count',
          body: jsonEncode({'post_id': like['item_id']}),
        );
      }
    } catch (_) {
      await _addToBoxWithLimit(queueBox, {
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
      await functions.createExecution(
        functionId: 'increment_repost_count',
        body: jsonEncode({'post_id': repost['post_id']}),
      );
      final comment = repost['comment'];
      if (comment != null &&
          comment.toString().isNotEmpty &&
          Get.isRegistered<NotificationService>()) {
        try {
          final res = await databases.getDocument(
            databaseId: databaseId,
            collectionId: postsCollectionId,
            documentId: repost['post_id'],
          );
          final userId = res.data['user_id'];
          await Get.find<NotificationService>().createNotification(
            userId,
            repost['user_id'],
            'repost',
            itemId: repost['post_id'],
            itemType: 'post',
          );
        } catch (_) {}
      }
      return doc.$id;
    } catch (_) {
      await _addToBoxWithLimit(queueBox, {
        'action': 'repost',
        'data': repost,
        '_cachedAt': DateTime.now().toIso8601String(),
      });
      return null;
    }
  }

  Future<void> deleteRepost(String repostId, String postId) async {
    try {
      await databases.deleteDocument(
        databaseId: databaseId,
        collectionId: repostsCollectionId,
        documentId: repostId,
      );
      await functions.createExecution(
        functionId: 'decrement_repost_count',
        body: jsonEncode({'post_id': postId}),
      );
    } catch (_) {
      await _addToBoxWithLimit(queueBox, {
        'action': 'delete_repost',
        'id': repostId,
        'post_id': postId,
        '_cachedAt': DateTime.now().toIso8601String(),
      });
      rethrow;
    }
  }

  Future<void> saveHashtags(List<String> tags) async {
    final uniqueTags = <String>{for (final t in tags) t.toLowerCase()};
    for (final tag in uniqueTags) {
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
        await hashtagsBox.put(tag, {
          'hashtag': tag,
          'last_used_at': DateTime.now().toIso8601String(),
        });
      } catch (_) {
        await hashtagsBox.put(tag, {
          'hashtag': tag,
          'last_used_at': DateTime.now().toIso8601String(),
        });
        await _addToBoxWithLimit(queueBox, {
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

  Future<void> deleteLike(
    String likeId, {
    required String itemId,
    required String itemType,
  }) async {
    try {
      await databases.deleteDocument(
        databaseId: databaseId,
        collectionId: likesCollectionId,
        documentId: likeId,
      );
      if (itemType == 'comment') {
        await functions.createExecution(
          functionId: 'decrement_comment_like_count',
          body: jsonEncode({'comment_id': itemId}),
        );
      } else {
        await functions.createExecution(
          functionId: 'decrement_like_count',
          body: jsonEncode({'post_id': itemId}),
        );
      }
    } catch (_) {
      await _addToBoxWithLimit(queueBox, {
        'action': 'unlike',
        'like_id': likeId,
        'item_id': itemId,
        'item_type': itemType,
        '_cachedAt': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> likeComment(String commentId, String userId) async {
    await createLike({
      'item_id': commentId,
      'item_type': 'comment',
      'user_id': userId,
    });
  }

  Future<void> unlikeComment(String likeId, String commentId) async {
    await deleteLike(
      likeId,
      itemId: commentId,
      itemType: 'comment',
    );
  }

  Future<void> likeRepost(String repostId, String userId) async {
    await createLike({
      'item_id': repostId,
      'item_type': 'repost',
      'user_id': userId,
    });
  }

  Future<void> unlikeRepost(String likeId, String repostId) async {
    await deleteLike(
      likeId,
      itemId: repostId,
      itemType: 'post',
    );
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
    final limited = _limitHashtags(hashtags);
    try {
      final doc = await databases.getDocument(
        databaseId: databaseId,
        collectionId: postsCollectionId,
        documentId: postId,
      );
      final createdAtStr = doc.data['\$createdAt'] ?? doc.data['createdAt'];
      final createdAt =
          createdAtStr != null ? DateTime.parse(createdAtStr) : DateTime.now();
      if (DateTime.now().difference(createdAt).inMinutes > 30) {
        throw Exception('Edit window expired');
      }
      await databases.updateDocument(
        databaseId: databaseId,
        collectionId: postsCollectionId,
        documentId: postId,
        data: {
          'content': content,
          'hashtags': limited,
          'mentions': mentions,
          'is_edited': true,
          'edited_at': DateTime.now().toIso8601String(),
        },
      );

      for (final key in postsBox.keys) {
        final cached = postsBox.get(key, defaultValue: []) as List;
        final index =
            cached.indexWhere((p) => p['id'] == postId || p['\$id'] == postId);
        if (index != -1) {
          cached[index] = {
            ...cached[index],
            'content': content,
            'hashtags': limited,
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
          case 'remove_bookmark':
            final data = Map<String, dynamic>.from(item['data']);
            await removeBookmark(data['bookmark_id']);
            break;
          case 'comment':
            final c =
                PostComment.fromJson(Map<String, dynamic>.from(item['data']));
            final newId = await createComment(c);
            await commentsBox.delete(c.id);
            final listKey = 'comments_${c.postId}';
            final list = (commentsBox.get(listKey, defaultValue: []) as List)
                .cast<dynamic>();
            final index =
                list.indexWhere((e) => e['id'] == c.id || e['\$id'] == c.id);
            if (index != -1) {
              list.removeAt(index);
            }
            if (newId != null) {
              final map = {...c.toJson(), 'id': newId};
              await commentsBox.put(newId, map);
              list.add(map);
              if (Get.isRegistered<CommentsController>()) {
                final controller = Get.find<CommentsController>();
                final i =
                    controller.comments.indexWhere((com) => com.id == c.id);
                if (i != -1) {
                  controller.comments[i] = PostComment(
                    id: newId,
                    postId: controller.comments[i].postId,
                    userId: controller.comments[i].userId,
                    username: controller.comments[i].username,
                    userAvatar: controller.comments[i].userAvatar,
                    parentId: controller.comments[i].parentId,
                    content: controller.comments[i].content,
                    mediaUrls: controller.comments[i].mediaUrls,
                    likeCount: controller.comments[i].likeCount,
                    replyCount: controller.comments[i].replyCount,
                    isDeleted: controller.comments[i].isDeleted,
                  );
                }
              }
            }
            await commentsBox.put(listKey, list);
            break;
          case 'unlike':
            await deleteLike(
              item['like_id'],
              itemId: item['item_id'],
              itemType: item['item_type'],
            );
            break;
          case 'delete_repost':
            await deleteRepost(item['id'], item['post_id']);
            break;
          case 'post':
            await createPost(
                FeedPost.fromJson(Map<String, dynamic>.from(item['data'])));
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
            final tag = (item['data'] as String).toLowerCase();
            await saveHashtags([tag]);
            await hashtagsBox.put(tag, {
              'hashtag': tag,
              'last_used_at': DateTime.now().toIso8601String(),
            });
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
      await _addToBoxWithLimit(queueBox, {
        'action': 'bookmark',
        'data': {'user_id': userId, 'post_id': postId},
        '_cachedAt': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> removeBookmark(String bookmarkId) async {
    try {
      await databases.deleteDocument(
        databaseId: databaseId,
        collectionId: bookmarksCollectionId,
        documentId: bookmarkId,
      );
    } catch (_) {
      await _addToBoxWithLimit(queueBox, {
        'action': 'remove_bookmark',
        'data': {'bookmark_id': bookmarkId},
        '_cachedAt': DateTime.now().toIso8601String(),
      });
      rethrow;
    }
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

  Future<void> deleteComment(PostComment comment) async {
    try {
      await databases.updateDocument(
        databaseId: databaseId,
        collectionId: commentsCollectionId,
        documentId: comment.id,
        data: {'is_deleted': true},
      );
      await functions.createExecution(
        functionId: comment.parentId == null
            ? 'decrement_comment_count'
            : 'decrement_reply_count',
        body: jsonEncode(comment.parentId == null
            ? {'post_id': comment.postId}
            : {'comment_id': comment.parentId}),
      );
      for (final key in commentsBox.keys) {
        final cached = commentsBox.get(key, defaultValue: []) as List;
        final index = cached.indexWhere(
          (c) => c['id'] == comment.id || c['\$id'] == comment.id,
        );
        if (index != -1) {
          cached[index] = {...cached[index], 'is_deleted': true};
          await commentsBox.put(key, cached);
        }
        if (comment.parentId != null) {
          final pIndex = cached.indexWhere(
            (c) => c['id'] == comment.parentId || c['\$id'] == comment.parentId,
          );
          if (pIndex != -1) {
            final count = (cached[pIndex]['reply_count'] ?? 0) as int;
            cached[pIndex] = {
              ...cached[pIndex],
              'reply_count': count > 0 ? count - 1 : 0,
            };
            await commentsBox.put(key, cached);
          }
        }
      }
      if (comment.parentId == null) {
        for (final key in postsBox.keys) {
          final cached = postsBox.get(key, defaultValue: []) as List;
          final index = cached.indexWhere(
            (p) => p['id'] == comment.postId || p['\$id'] == comment.postId,
          );
          if (index != -1) {
            final count = (cached[index]['comment_count'] ?? 0) as int;
            cached[index] = {
              ...cached[index],
              'comment_count': count > 0 ? count - 1 : 0,
            };
            await postsBox.put(key, cached);
          }
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
      await _addToBoxWithLimit(queueBox, {
        'action': 'follow',
        'data': follow,
        '_cachedAt': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<List<FeedPost>> fetchSortedPosts(String sortType,
      {String? roomId}) async {
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
      final posts = result.documents
          .map((e) => FeedPost.fromJson(e.data))
          .where((p) => !p.isDeleted)
          .toList();
      final cache = posts
          .map((e) =>
              {...e.toJson(), '_cachedAt': DateTime.now().toIso8601String()})
          .toList();
      await postsBox.put(key, cache);
      return posts;
    } catch (_) {
      final cached = postsBox.get(key, defaultValue: []) as List;
      return cached
          .map((e) => FeedPost.fromJson(Map<String, dynamic>.from(e)))
          .where((p) => !p.isDeleted)
          .toList();
    }
  }

  Future<String> sharePost(String postId) async {
    try {
      await functions.createExecution(
        functionId: 'increment_share_count',
        body: jsonEncode({'post_id': postId}),
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
