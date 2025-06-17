import 'package:appwrite/appwrite.dart';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'dart:convert';
import '../models/feed_post.dart';
import '../models/post_comment.dart';
import '../models/post_like.dart';
import '../models/post_repost.dart';
import '../../bookmarks/models/bookmark.dart';
import '../../notifications/services/notification_service.dart';
import '../controllers/comments_controller.dart';
import 'mention_service.dart';
import '../../../shared/utils/logger.dart';

Future<XFile?> _compressImage(String path) async {
  return FlutterImageCompress.compressAndGetFile(
    path,
    '${path}_compressed.jpg',
    quality: 80,
  );
}

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
  final String validateReactionFunctionId;
  final Connectivity connectivity;
  final Box postsBox = Hive.box('posts');
  final Box commentsBox = Hive.box('comments');
  final Box bookmarksBox = Hive.box('bookmarks');
  final Box reactionsBox = Hive.box('reactions');
  final Box hashtagsBox = Hive.box('hashtags');
  final Box queueBox = Hive.box('action_queue');
  final Box postQueueBox = Hive.box('post_queue');

  Future<void> cleanupCachedEntries() async {
    final expiry = DateTime.now().subtract(const Duration(days: 30));

    Future<void> cleanBox(Box box) async {
      final keys = box.keys.toList();
      for (final key in keys) {
        final value = box.get(key);
        if (value is Map) {
          final ts = DateTime.tryParse(value['_cachedAt'] ?? '');
          if (ts != null && ts.isBefore(expiry)) {
            await box.delete(key);
          }
        } else if (value is List) {
          final cleaned = value.where((element) {
            if (element is Map) {
              final ts = DateTime.tryParse(element['_cachedAt'] ?? '');
              return ts == null || ts.isAfter(expiry);
            }
            return true;
          }).toList();
          if (cleaned.isEmpty) {
            await box.delete(key);
          } else if (cleaned.length != value.length) {
            await box.put(key, cleaned);
          }
        }
      }
    }

    await cleanBox(postsBox);
    await cleanBox(commentsBox);
    await cleanBox(bookmarksBox);
    await cleanBox(queueBox);
    await cleanBox(postQueueBox);
    final reactionKeys = reactionsBox.keys.toList();
    for (final key in reactionKeys) {
      final value = reactionsBox.get(key);
      if (value is Map) {
        final ts = DateTime.tryParse(value['likedAt'] ?? '');
        if (ts != null && ts.isBefore(expiry)) {
          await reactionsBox.delete(key);
        }
      }
    }
  }

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
    required this.validateReactionFunctionId,
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

  List<String> _limitMentions(List<String> names) =>
      names.length > 10 ? names.sublist(0, 10) : names;

  Future<bool> validateReaction(
    String type,
    String itemId,
    String userId,
  ) async {
    try {
      final result = await functions.createExecution(
        functionId: validateReactionFunctionId,
        body: jsonEncode({
          'type': type,
          'item_id': itemId,
          'user_id': userId,
        }),
      );
      final data =
          jsonDecode(result.responseBody) as Map<String, dynamic>? ?? {};
      return data['duplicate'] == true;
    } catch (e, st) {
      logger.e('validateReaction failed', error: e, stackTrace: st);
      return false;
    }
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
          .map((e) =>
              {...e.toJson(), '_cachedAt': DateTime.now().toIso8601String()})
          .toList();
      await postsBox.put('posts_$roomId', cache);
      return posts;
    } catch (e, st) {
      logger.e('getPosts failed', error: e, stackTrace: st);
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

  Future<FeedPost?> getPostById(String postId) async {
    try {
      final doc = await databases.getDocument(
        databaseId: databaseId,
        collectionId: postsCollectionId,
        documentId: postId,
      );
      return FeedPost.fromJson(doc.data);
    } catch (e, st) {
      logger.e('getPostById failed', error: e, stackTrace: st);
      for (final key in postsBox.keys) {
        final cached = postsBox.get(key, defaultValue: []) as List;
        for (final item in cached) {
          if (item is Map &&
              (item['id'] == postId || item['\$id'] == postId)) {
            return FeedPost.fromJson(Map<String, dynamic>.from(item));
          }
        }
      }
      return null;
    }
  }

  Future<String?> createPost(FeedPost post) async {
    final limitedTags = _limitHashtags(post.hashtags);
    final limitedMentions = _limitMentions(post.mentions);
    final toSave =
        limitedTags.length == post.hashtags.length &&
                limitedMentions.length == post.mentions.length
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
                hashtags: limitedTags,
                mentions: limitedMentions,
                isEdited: post.isEdited,
                isDeleted: post.isDeleted,
                editedAt: post.editedAt,
                createdAt: post.createdAt,
              );
    try {
      final doc = await databases.createDocument(
        databaseId: databaseId,
        collectionId: postsCollectionId,
        documentId: ID.unique(),
        data: toSave.toJson(),
      );
      return doc.data['\$id'] ?? doc.data['id'];
    } catch (e, st) {
      logger.e('createPost failed', error: e, stackTrace: st);
      await _addToBoxWithLimit(queueBox, {
        'action': 'post',
        'data': toSave.toJson(),
        '_cachedAt': DateTime.now().toIso8601String(),
      });
      return null;
    }
  }

  Future<String> uploadImage(File image) async {
    final compressed = await compute(_compressImage, image.path);
    final result = await storage.createFile(
      bucketId: 'post_images',
      fileId: ID.unique(),
      file: InputFile.fromPath(path: compressed!.path),
    );
    return '${storage.client.endPoint}/storage/buckets/post_images/files/${result.$id}/view?project=${storage.client.config['project']}';
  }

  Future<String?> createPostWithImage(
    String userId,
    String username,
    String content,
    String? roomId,
    File image, {
    List<String> hashtags = const [],
    List<String> mentions = const [],
  }) async {
    final limited = _limitHashtags(hashtags);
    final limitedMentions = _limitMentions(mentions);
    try {
      final imageUrl = await uploadImage(image);
      final now = DateTime.now();
      final post = FeedPost(
        id: now.toIso8601String(),
        roomId: roomId ?? '',
        userId: userId,
        username: username,
        content: content,
        mediaUrls: [imageUrl],
        hashtags: limited,
        mentions: limitedMentions,
        createdAt: now,
      );
      return await createPost(post);
    } catch (e, st) {
      logger.e('createPostWithImage failed', error: e, stackTrace: st);
      await _addToBoxWithLimit(postQueueBox, {
        'action': 'post_with_image',
        'user_id': userId,
        'username': username,
        'content': content,
        'room_id': roomId,
        'image_path': image.path,
        'hashtags': limited,
        'mentions': limitedMentions,
        '_cachedAt': DateTime.now().toIso8601String(),
      });
      Get.snackbar('Offline', 'Image post queued for syncing');
      return null;
    }
  }

  Future<Map<String, dynamic>> fetchLinkMetadata(String url) async {
    final result = await functions.createExecution(
      functionId: linkMetadataFunctionId,
      body: jsonEncode({'url': url}),
    );
    return jsonDecode(result.responseBody) as Map<String, dynamic>;
  }

  Future<String?> createPostWithLink(
    String userId,
    String username,
    String content,
    String? roomId,
    String linkUrl, {
    List<String> hashtags = const [],
    List<String> mentions = const [],
  }) async {
    final limited = _limitHashtags(hashtags);
    final limitedMentions = _limitMentions(mentions);
    try {
      final metadata = await fetchLinkMetadata(linkUrl);
      final now2 = DateTime.now();
      final post = FeedPost(
        id: now2.toIso8601String(),
        roomId: roomId ?? '',
        userId: userId,
        username: username,
        content: content,
        linkUrl: linkUrl,
        linkMetadata: metadata,
        hashtags: limited,
        mentions: limitedMentions,
        createdAt: now2,
      );
      return await createPost(post);
    } catch (e, st) {
      logger.e('createPostWithLink failed', error: e, stackTrace: st);
      await _addToBoxWithLimit(queueBox, {
        'action': 'post_with_link',
        'user_id': userId,
        'username': username,
        'content': content,
        'room_id': roomId,
        'link_url': linkUrl,
        'hashtags': limited,
        'mentions': limitedMentions,
        '_cachedAt': DateTime.now().toIso8601String(),
      });
      Get.snackbar('Offline', 'Link post queued for syncing');
      return null;
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
    } catch (e, st) {
      logger.e('getComments failed', error: e, stackTrace: st);
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
        data: comment.toJson(includeId: false, includeMentions: true),
      );
      id = doc.data['\$id'] ?? doc.data['id'];
      await databases.updateDocument(
        databaseId: databaseId,
        collectionId: postsCollectionId,
        documentId: comment.postId,
          data: {
            'comment_count': {r'$increment': 1}
          },
      );
      if (comment.parentId != null) {
        await databases.updateDocument(
          databaseId: databaseId,
          collectionId: commentsCollectionId,
          documentId: comment.parentId!,
          data: {
            'reply_count': {r'$increment': 1}
          },
        );
        if (Get.isRegistered<NotificationService>()) {
          try {
            final parent = await databases.getDocument(
              databaseId: databaseId,
              collectionId: commentsCollectionId,
              documentId: comment.parentId!,
            );
            final parentAuthor = parent.data['user_id'];
            if (parentAuthor != comment.userId) {
              await Get.find<NotificationService>().createNotification(
                parentAuthor,
                comment.userId,
                'reply',
                itemId: comment.parentId,
                itemType: 'comment',
              );
            }
          } catch (e, st) {
            logger.e('notify parent comment failed', error: e, stackTrace: st);
          }
        }
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
        } catch (e, st) {
          logger.e('notify post owner failed', error: e, stackTrace: st);
        }
      }
      } catch (e, st) {
      logger.e('createComment failed', error: e, stackTrace: st);
      await commentsBox.put(
        comment.id,
        {
          ...comment.toJson(includeId: true),
          '_cachedAt': DateTime.now().toIso8601String(),
        },
      );
      final listKey = 'comments_${comment.postId}';
      final current =
          (commentsBox.get(listKey, defaultValue: []) as List).cast<dynamic>();
      current.add({
        ...comment.toJson(includeId: true),
        '_cachedAt': DateTime.now().toIso8601String(),
      });
      await commentsBox.put(listKey, current);
      await _addToBoxWithLimit(queueBox, {
        'action': 'comment',
        'data': comment.toJson(includeId: true),
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
      final existing =
          await getUserLike(like['item_id'] as String, like['user_id'] as String);
      if (existing != null) return;
      await databases.createDocument(
        databaseId: databaseId,
        collectionId: likesCollectionId,
        documentId: ID.unique(),
        data: like,
      );
      if (like['item_type'] == 'comment') {
        await databases.updateDocument(
          databaseId: databaseId,
          collectionId: commentsCollectionId,
          documentId: like['item_id'],
          data: {
            'like_count': {r'$increment': 1}
          },
        );
      } else {
        await databases.updateDocument(
          databaseId: databaseId,
          collectionId: postsCollectionId,
          documentId: like['item_id'],
          data: {
            'like_count': {r'$increment': 1}
          },
        );
      }
      if (Get.isRegistered<NotificationService>()) {
        try {
          String ownerId;
          switch (like['item_type']) {
            case 'comment':
              final res = await databases.getDocument(
                databaseId: databaseId,
                collectionId: commentsCollectionId,
                documentId: like['item_id'],
              );
              ownerId = res.data['user_id'];
              break;
            case 'repost':
              final res = await databases.getDocument(
                databaseId: databaseId,
                collectionId: repostsCollectionId,
                documentId: like['item_id'],
              );
              ownerId = res.data['user_id'];
              break;
            default:
              final res = await databases.getDocument(
                databaseId: databaseId,
                collectionId: postsCollectionId,
                documentId: like['item_id'],
              );
              ownerId = res.data['user_id'];
          }
          if (ownerId != like['user_id']) {
            await Get.find<NotificationService>().createNotification(
              ownerId,
              like['user_id'],
              'like',
              itemId: like['item_id'],
              itemType: like['item_type'],
            );
          }
        } catch (e, st) {
          logger.e('notify like owner failed', error: e, stackTrace: st);
        }
      }
    } catch (e, st) {
      logger.e('createLike failed', error: e, stackTrace: st);
      await _addToBoxWithLimit(queueBox, {
        'action': 'like',
        'data': like,
        '_cachedAt': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<String?> createRepost(Map<String, dynamic> repost) async {
    try {
      final existing =
          await getUserRepost(repost['post_id'], repost['user_id']);
      if (existing != null) return existing.id;
      final doc = await databases.createDocument(
        databaseId: databaseId,
        collectionId: repostsCollectionId,
        documentId: ID.unique(),
        data: repost,
      );
      await databases.updateDocument(
        databaseId: databaseId,
        collectionId: postsCollectionId,
        documentId: repost['post_id'],
        data: {
          'repost_count': {r'$increment': 1}
        },
      );
      try {
        final res = await databases.getDocument(
          databaseId: databaseId,
          collectionId: postsCollectionId,
          documentId: repost['post_id'],
        );
        final ownerId = res.data['user_id'];
        if (Get.isRegistered<NotificationService>()) {
          await Get.find<NotificationService>().createNotification(
            ownerId,
            repost['user_id'],
            'repost',
            itemId: repost['post_id'],
            itemType: 'post',
          );
        }
      } catch (e, st) {
        logger.e('notify repost owner failed', error: e, stackTrace: st);
      }
      return doc.$id;
    } catch (e, st) {
      logger.e('createRepost failed', error: e, stackTrace: st);
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
      await databases.updateDocument(
        databaseId: databaseId,
        collectionId: postsCollectionId,
        documentId: postId,
        data: {
          'repost_count': {r'$increment': -1}
        },
      );
    } catch (e, st) {
      logger.e('deleteRepost failed', error: e, stackTrace: st);
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
      } catch (e, st) {
        logger.e('saveHashtags failed', error: e, stackTrace: st);
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

  Future<Map<String, PostLike>> getUserLikesBulk(
    List<String> itemIds,
    String userId, {
    String itemType = 'post',
  }) async {
    if (itemIds.isEmpty) return {};
    final res = await databases.listDocuments(
      databaseId: databaseId,
      collectionId: likesCollectionId,
      queries: [
        Query.equal('user_id', userId),
        Query.equal('item_id', itemIds),
        if (itemType.isNotEmpty) Query.equal('item_type', itemType),
      ],
    );
    return {
      for (final doc in res.documents)
        doc.data['item_id']: PostLike.fromJson(doc.data)
    };
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
        await databases.updateDocument(
          databaseId: databaseId,
          collectionId: commentsCollectionId,
          documentId: itemId,
          data: {
            'like_count': {r'$increment': -1}
          },
        );
      } else {
        await databases.updateDocument(
          databaseId: databaseId,
          collectionId: postsCollectionId,
          documentId: itemId,
          data: {
            'like_count': {r'$increment': -1}
          },
        );
      }
    } catch (e, st) {
      logger.e('deleteLike failed', error: e, stackTrace: st);
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

  Future<Map<String, PostRepost>> getUserRepostsBulk(
    List<String> postIds,
    String userId,
  ) async {
    if (postIds.isEmpty) return {};
    final res = await databases.listDocuments(
      databaseId: databaseId,
      collectionId: repostsCollectionId,
      queries: [
        Query.equal('user_id', userId),
        Query.equal('post_id', postIds),
      ],
    );
    return {
      for (final doc in res.documents)
        doc.data['post_id']: PostRepost.fromJson(doc.data)
    };
  }

  Future<void> editPost(
    String postId,
    String content,
    List<String> hashtags,
    List<String> mentions,
  ) async {
    final limited = _limitHashtags(hashtags);
    final limitedMentions = _limitMentions(mentions);
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
          'mentions': limitedMentions,
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
            'mentions': limitedMentions,
            'is_edited': true,
            'edited_at': DateTime.now().toIso8601String(),
          };
          await postsBox.put(key, cached);
        }
      }
    } catch (e, st) {
      logger.e('editPost failed', error: e, stackTrace: st);
      throw Exception('Failed to edit post: $e');
    }
  }

  Future<void> syncQueuedActions() async {
    final expiry = DateTime.now().subtract(const Duration(days: 30));
    final keys = queueBox.keys.toList();
    for (final key in keys) {
      final item = queueBox.get(key);
      if (item == null || item is! Map) {
        await queueBox.delete(key);
        continue;
      }
      final Map mapItem = Map<String, dynamic>.from(item);
      final ts = DateTime.tryParse(mapItem['_cachedAt'] ?? '');
      if (ts != null && ts.isBefore(expiry)) {
        await queueBox.delete(key);
        continue;
      }
      try {
        switch (mapItem['action']) {
          case 'like':
            await createLike(Map<String, dynamic>.from(mapItem['data']));
            break;
          case 'repost':
            await createRepost(Map<String, dynamic>.from(mapItem['data']));
            break;
          case 'bookmark':
            final data = Map<String, dynamic>.from(mapItem['data']);
            await bookmarkPost(data['user_id'], data['post_id']);
            break;
          case 'remove_bookmark':
            final data = Map<String, dynamic>.from(mapItem['data']);
            await removeBookmark(data['bookmark_id']);
            break;
          case 'comment':
            final c =
                PostComment.fromJson(Map<String, dynamic>.from(mapItem['data']));
            final newId = await createComment(c);
            final mentionNames = _limitMentions(c.mentions);
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
            if (newId != null && Get.isRegistered<MentionService>()) {
              await Get.find<MentionService>().notifyMentions(
                mentionNames,
                newId,
                'comment',
              );
            }
            break;
          case 'unlike':
            await deleteLike(
              mapItem['like_id'],
              itemId: mapItem['item_id'],
              itemType: mapItem['item_type'],
            );
            break;
          case 'delete_repost':
            await deleteRepost(mapItem['id'], mapItem['post_id']);
            break;
          case 'share':
            await sharePost(mapItem['post_id']);
            break;
          case 'post':
            final post =
                FeedPost.fromJson(Map<String, dynamic>.from(mapItem['data']));
            final newId = await createPost(post);
            if (newId != null && Get.isRegistered<MentionService>()) {
              await Get.find<MentionService>().notifyMentions(
                post.mentions,
                newId,
                'post',
              );
            }
            break;
          case 'post_with_link':
            final linkMentions =
                (mapItem['mentions'] as List?)?.cast<String>() ?? const [];
            final metadata = await fetchLinkMetadata(mapItem['link_url']);
            final now = DateTime.now();
            final post = FeedPost(
              id: now.toIso8601String(),
              roomId: mapItem['room_id'] ?? '',
              userId: mapItem['user_id'],
              username: mapItem['username'],
              content: mapItem['content'],
              linkUrl: mapItem['link_url'],
              linkMetadata: metadata,
              hashtags:
                  (mapItem['hashtags'] as List?)?.cast<String>() ?? const [],
              mentions: linkMentions,
              createdAt: now,
            );
            final newId = await createPost(post);
            if (newId != null && Get.isRegistered<MentionService>()) {
              await Get.find<MentionService>().notifyMentions(
                linkMentions,
                newId,
                'post',
              );
            }
            break;
          case 'hashtag':
            final tag = (mapItem['data'] as String).toLowerCase();
            await saveHashtags([tag]);
            await hashtagsBox.put(tag, {
              'hashtag': tag,
              'last_used_at': DateTime.now().toIso8601String(),
            });
            break;
          case 'follow':
            await createFollow(Map<String, dynamic>.from(mapItem['data']));
            break;
          case 'unfollow':
            final data = Map<String, dynamic>.from(mapItem['data']);
            await deleteFollow(data['follower_id'], data['followed_id']);
            break;
        }
        await queueBox.delete(key);
      } catch (e, st) {
        logger.e('syncQueuedActions item failed', error: e, stackTrace: st);
      }
    }

    final imageKeys = postQueueBox.keys.toList();
    for (final key in imageKeys) {
      final item = postQueueBox.get(key);
      if (item == null || item is! Map) {
        await postQueueBox.delete(key);
        continue;
      }
      final Map mapItem = Map<String, dynamic>.from(item);
      final ts = DateTime.tryParse(mapItem['_cachedAt'] ?? '');
      if (ts != null && ts.isBefore(expiry)) {
        await postQueueBox.delete(key);
        continue;
      }
      try {
        if (mapItem['action'] == 'post_with_image') {
          final file = File(mapItem['image_path']);
          final imageUrl = await uploadImage(file);
          final mentions =
              (mapItem['mentions'] as List?)?.cast<String>() ?? const [];
          final now = DateTime.now();
          final post = FeedPost(
            id: now.toIso8601String(),
            roomId: mapItem['room_id'] ?? '',
            userId: mapItem['user_id'],
            username: mapItem['username'],
            content: mapItem['content'],
            mediaUrls: [imageUrl],
            hashtags: (mapItem['hashtags'] as List?)?.cast<String>() ?? const [],
            mentions: mentions,
            createdAt: now,
          );
          final newId = await createPost(post);
          if (newId != null && Get.isRegistered<MentionService>()) {
            await Get.find<MentionService>().notifyMentions(
              mentions,
              newId,
              'post',
            );
          }
        }
        await postQueueBox.delete(key);
      } catch (e, st) {
        logger.e('syncQueuedActions post image failed', error: e, stackTrace: st);
      }
    }

    await cleanupCachedEntries();
  }

  Future<void> bookmarkPost(String userId, String postId) async {
    try {
      final existing = await getUserBookmark(postId, userId);
      if (existing != null) return;
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
      await databases.updateDocument(
        databaseId: databaseId,
        collectionId: postsCollectionId,
        documentId: postId,
        data: {
          'bookmark_count': {r'$increment': 1}
        },
      );
      for (final key in postsBox.keys) {
        final cached = postsBox.get(key, defaultValue: []) as List;
        final index = cached.indexWhere(
          (p) => p['id'] == postId || p['\$id'] == postId,
        );
        if (index != -1) {
          final count = (cached[index]['bookmark_count'] ?? 0) as int;
          cached[index] = {
            ...cached[index],
            'bookmark_count': count + 1,
          };
          await postsBox.put(key, cached);
        }
      }

      if (Get.isRegistered<NotificationService>()) {
        try {
          final post = await databases.getDocument(
            databaseId: databaseId,
            collectionId: postsCollectionId,
            documentId: postId,
          );
          final ownerId = post.data['user_id'];
          if (ownerId != userId) {
            await Get.find<NotificationService>().createNotification(
              ownerId,
              userId,
              'bookmark',
              itemId: postId,
              itemType: 'post',
            );
          }
        } catch (e, st) {
          logger.e('bookmark notification failed', error: e, stackTrace: st);
        }
      }
    } catch (e, st) {
      logger.e('bookmarkPost failed', error: e, stackTrace: st);
      await _addToBoxWithLimit(queueBox, {
        'action': 'bookmark',
        'data': {'user_id': userId, 'post_id': postId},
        '_cachedAt': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> removeBookmark(String bookmarkId) async {
    try {
      final doc = await databases.getDocument(
        databaseId: databaseId,
        collectionId: bookmarksCollectionId,
        documentId: bookmarkId,
      );
      final postId = doc.data['post_id'] as String;
      await databases.deleteDocument(
        databaseId: databaseId,
        collectionId: bookmarksCollectionId,
        documentId: bookmarkId,
      );
      await databases.updateDocument(
        databaseId: databaseId,
        collectionId: postsCollectionId,
        documentId: postId,
        data: {
          'bookmark_count': {r'$increment': -1}
        },
      );
      for (final key in postsBox.keys) {
        final cached = postsBox.get(key, defaultValue: []) as List;
        final index = cached.indexWhere(
          (p) => p['id'] == postId || p['\$id'] == postId,
        );
        if (index != -1) {
          final count = (cached[index]['bookmark_count'] ?? 0) as int;
          cached[index] = {
            ...cached[index],
            'bookmark_count': count > 0 ? count - 1 : 0,
          };
          await postsBox.put(key, cached);
        }
      }
    } catch (e, st) {
      logger.e('removeBookmark failed', error: e, stackTrace: st);
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
    } catch (e, st) {
      logger.e('deletePost failed', error: e, stackTrace: st);
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
      await databases.updateDocument(
        databaseId: databaseId,
        collectionId:
            comment.parentId == null ? postsCollectionId : commentsCollectionId,
        documentId:
            comment.parentId == null ? comment.postId : comment.parentId!,
        data: {
          if (comment.parentId == null)
            'comment_count': {r'$increment': -1}
          else
            'reply_count': {r'$increment': -1}
        },
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
    } catch (e, st) {
      logger.e('deleteComment failed', error: e, stackTrace: st);
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
    } catch (e, st) {
      logger.e('listBookmarks failed', error: e, stackTrace: st);
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
    } catch (e, st) {
      logger.e('createFollow failed', error: e, stackTrace: st);
      await _addToBoxWithLimit(queueBox, {
        'action': 'follow',
        'data': follow,
        '_cachedAt': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> deleteFollow(String followerId, String followedId) async {
    try {
      final res = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: 'follows',
        queries: [
          Query.equal('follower_id', followerId),
          Query.equal('followed_id', followedId),
        ],
      );
      for (final doc in res.documents) {
        await databases.deleteDocument(
          databaseId: databaseId,
          collectionId: 'follows',
          documentId: doc.$id,
        );
      }
    } catch (e, st) {
      logger.e('deleteFollow failed', error: e, stackTrace: st);
      await _addToBoxWithLimit(queueBox, {
        'action': 'unfollow',
        'data': {
          'follower_id': followerId,
          'followed_id': followedId,
        },
        '_cachedAt': DateTime.now().toIso8601String(),
      });
      rethrow;
    }
  }

  Future<List<FeedPost>> fetchSortedPosts(
    String sortType, {
    String? roomId,
    String? cursor,
    int limit = 20,
  }) async {
    final queries = <String>[Query.limit(limit)];
    if (roomId != null) {
      queries.add(Query.equal('room_id', roomId));
    }
    if (cursor != null) {
      queries.add(Query.cursorAfter(cursor));
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
      final existing =
          (postsBox.get(key, defaultValue: []) as List).cast<dynamic>();
      final cache = posts
          .map((e) =>
              {...e.toJson(), '_cachedAt': DateTime.now().toIso8601String()})
          .toList();
      await postsBox.put(key, cursor == null ? cache : [...existing, ...cache]);
      return posts;
    } catch (e, st) {
      logger.e('fetchSortedPosts failed', error: e, stackTrace: st);
      final cached = postsBox.get(key, defaultValue: []) as List;
      final expiry = DateTime.now().subtract(const Duration(days: 30));
      var list = cached
          .where((e) {
            final ts = DateTime.tryParse(e['_cachedAt'] ?? '');
            return ts == null || ts.isAfter(expiry);
          })
          .map((e) => FeedPost.fromJson(Map<String, dynamic>.from(e)))
          .where((p) => !p.isDeleted)
          .toList();
      if (cursor != null) {
        final index = list.indexWhere((p) => p.id == cursor);
        if (index != -1) list = list.sublist(index + 1);
      }
      return list.take(limit).toList();
    }
  }

  Future<String> sharePost(String postId) async {
    try {
      await databases.updateDocument(
        databaseId: databaseId,
        collectionId: postsCollectionId,
        documentId: postId,
        data: {
          'share_count': {r'$increment': 1}
        },
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
    } catch (e, st) {
      logger.e('sharePost failed', error: e, stackTrace: st);
      await _addToBoxWithLimit(queueBox, {
        'action': 'share',
        'post_id': postId,
        '_cachedAt': DateTime.now().toIso8601String(),
      });
      return 'https://your-app.com/post/$postId';
    }
  }
}
