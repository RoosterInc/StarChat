import 'dart:math' as math;
import 'package:get/get.dart';
import 'package:appwrite/appwrite.dart';
import '../../authentication/controllers/auth_controller.dart';
import '../controllers/feed_controller.dart';
import '../models/post_comment.dart';
import "../../profile/services/activity_service.dart";
import '../services/feed_service.dart';

class CommentsController extends GetxController {
  final FeedService service;
  final Realtime? realtime;

  CommentsController({required this.service, this.realtime}) {
    _realtime = realtime;
  }

  static const int maxDepth = 5;

  Realtime? _realtime;
  RealtimeSubscription? _subscription;
  String? _postId;

  final _comments = <PostComment>[].obs;
  List<PostComment> get comments => _comments;

  final _likedIds = <String, String>{}.obs; // commentId -> likeId
  final _likeCounts = <String, int>{}.obs; // commentId -> likes
  final _replyCounts = <String, int>{}.obs; // commentId -> replies

  final _isLoading = false.obs;
  bool get isLoading => _isLoading.value;

  String? _nextCursor;

  Future<void> loadComments(
    String postId, {
    int limit = 20,
    bool loadMore = false,
  }) async {
    _isLoading.value = true;
    try {
      final data = await service.getComments(
        postId,
        limit: limit,
        cursor: loadMore ? _nextCursor : null,
      );
      if (loadMore) {
        _comments.addAll(data);
      } else {
        _comments.assignAll(data);
      }
      _likeCounts.addAll({for (final c in data) c.id: c.likeCount});
      _replyCounts.addAll({for (final c in data) c.id: c.replyCount});
      final auth = Get.find<AuthController>();
      final uid = auth.userId;
      if (uid != null && data.isNotEmpty) {
        final ids = data.map((c) => c.id).toList();
        final likeMap =
            await service.getUserLikesBulk(ids, uid, itemType: 'comment');
        _likedIds.addAll({
          for (final entry in likeMap.entries) entry.key: entry.value.id
        });
      }
      if (data.isNotEmpty) _nextCursor = data.last.id;
      _listenToRealtime(postId);
    } finally {
      _isLoading.value = false;
    }
  }

  Future<String> addComment(PostComment comment) async {
    final id = await service.createComment(comment) ?? comment.id;
    final toAdd = id == comment.id
        ? comment
        : PostComment(
            id: id,
            postId: comment.postId,
            userId: comment.userId,
            username: comment.username,
            userAvatar: comment.userAvatar,
            parentId: comment.parentId,
            content: comment.content,
            mediaUrls: comment.mediaUrls,
            mentions: comment.mentions,
            likeCount: comment.likeCount,
            replyCount: comment.replyCount,
            isDeleted: comment.isDeleted,
          );
    _comments.add(toAdd);
    final action = comment.parentId == null ? 'comment' : 'reply';
    await Get.find<ActivityService>()
        .logActivity(comment.userId, action, itemId: id, itemType: 'comment');
    _likeCounts[id] = comment.likeCount;
    _replyCounts[id] = comment.replyCount;
    if (Get.isRegistered<FeedController>()) {
      Get.find<FeedController>().incrementCommentCount(comment.postId);
    }
    if (comment.parentId != null) {
      incrementReplyCount(comment.parentId!);
    }
    return id;
  }

  Future<String> replyToComment(PostComment comment) async {
    return await addComment(comment);
  }

  Future<void> toggleLikeComment(String commentId) async {
    final auth = Get.find<AuthController>();
    final uid = auth.userId;
    if (uid == null) return;
    final cacheKey = 'like:comment_${commentId}_$uid';
    if (!_likedIds.containsKey(commentId) &&
        service.reactionsBox.containsKey(cacheKey)) {
      return;
    }
    if (_likedIds.containsKey(commentId)) {
      final likeId = _likedIds.remove(commentId)!;
      try {
        await service.unlikeComment(likeId, commentId);
        service.reactionsBox.delete(cacheKey);
      } catch (_) {}
      _likeCounts[commentId] =
          math.max(0, (_likeCounts[commentId] ?? 1) - 1);
    } else {
      final isDup = await service.validateReaction('like', commentId, uid);
      if (!isDup) {
        await service.likeComment(commentId, uid);
      }
      try {
        final like = await service.getUserLike(commentId, uid);
        if (like != null) {
          _likedIds[commentId] = like.id;
        } else {
          _likedIds[commentId] = 'offline';
        }
      } catch (_) {
        _likedIds[commentId] = 'offline';
      }
      _likeCounts[commentId] = (_likeCounts[commentId] ?? 0) + 1;
      service.reactionsBox.put(cacheKey, {
        'itemId': commentId,
        'itemType': 'comment',
        'userId': uid,
        'likedAt': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> editComment(String commentId, String content) async {
    final index = _comments.indexWhere((c) => c.id == commentId);
    if (index == -1) return;
    await service.editComment(commentId, content);
    final existing = _comments[index];
    _comments[index] = PostComment(
      id: existing.id,
      postId: existing.postId,
      userId: existing.userId,
      username: existing.username,
      userAvatar: existing.userAvatar,
      parentId: existing.parentId,
      content: content,
      mediaUrls: existing.mediaUrls,
      mentions: existing.mentions,
      likeCount: existing.likeCount,
      replyCount: existing.replyCount,
      isDeleted: existing.isDeleted,
      isEdited: true,
      editedAt: DateTime.now(),
    );
  }

  Future<void> deleteComment(String commentId) async {
    final comment = _comments.firstWhereOrNull((c) => c.id == commentId);
    if (comment != null) {
      await service.deleteComment(comment);
    }
    _comments.removeWhere((c) => c.id == commentId);
    _likedIds.remove(commentId);
    _likeCounts.remove(commentId);
    if (comment != null) {
      _replyCounts.remove(commentId);
      if (Get.isRegistered<FeedController>()) {
        Get.find<FeedController>().decrementCommentCount(comment.postId);
      }
      if (comment.parentId != null) {
        decrementReplyCount(comment.parentId!);
      }
    }
  }

  bool isCommentLiked(String id) => _likedIds.containsKey(id);
  int commentLikeCount(String id) => _likeCounts[id] ?? 0;
  int commentReplyCount(String id) => _replyCounts[id] ?? 0;

  List<PostComment> getReplies(String commentId) {
    return _comments.where((c) => c.parentId == commentId).toList();
  }

  void incrementReplyCount(String commentId) {
    _replyCounts[commentId] = (_replyCounts[commentId] ?? 0) + 1;
  }

  void decrementReplyCount(String commentId) {
    _replyCounts[commentId] = math.max(0, (_replyCounts[commentId] ?? 1) - 1);
  }

  void _listenToRealtime(String postId) {
    if (_postId == postId && _subscription != null) return;
    final auth = Get.find<AuthController>();
    _postId = postId;
    _realtime ??= Realtime(auth.client);
    _subscription?.close();
    _subscription = _realtime!.subscribe([
      'databases.${service.databaseId}.collections.${service.commentsCollectionId}.documents',
    ]);
    _subscription!.stream.listen((event) {
      final payload = event.payload;

      if (payload['post_id'] == postId) {
        final id = payload['\$id'] ?? payload['id'];
        final comment = PostComment.fromJson(payload);
        if (event.events.any((e) => e.contains('.create'))) {
          if (!_comments.any((c) => c.id == id) && !comment.isDeleted) {
            _comments.add(comment);
            _likeCounts[id] = comment.likeCount;
            _replyCounts[id] = comment.replyCount;
            if (Get.isRegistered<FeedController>()) {
              Get.find<FeedController>().incrementCommentCount(comment.postId);
            }
            if (comment.parentId != null) {
              incrementReplyCount(comment.parentId!);
              for (final key in service.commentsBox.keys) {
                if (!key.toString().startsWith('comments_')) continue;
                final list = (service.commentsBox.get(key, defaultValue: []) as List).cast<dynamic>();
                final idx = list.indexWhere((c) => c['id'] == comment.parentId || c['\$id'] == comment.parentId);
                if (idx != -1) {
                  final count = (list[idx]['reply_count'] ?? 0) as int;
                  list[idx] = {
                    ...list[idx],
                    'reply_count': count + 1,
                  };
                  service.commentsBox.put(key, list);
                }
              }
            }
            final listKey = 'comments_${comment.postId}';
            final list = (service.commentsBox.get(listKey, defaultValue: []) as List).cast<dynamic>();
            list.add({...comment.toJson(), '_cachedAt': DateTime.now().toIso8601String()});
            service.commentsBox.put(listKey, list);
          }
        } else if ((event.events.any((e) => e.contains('.update')) && comment.isDeleted) ||
            event.events.any((e) => e.contains('.delete'))) {
          _comments.removeWhere((c) => c.id == id);
          _likedIds.remove(id);
          _likeCounts.remove(id);
          _replyCounts.remove(id);
          if (Get.isRegistered<FeedController>()) {
            Get.find<FeedController>().decrementCommentCount(comment.postId);
          }
          final parentId = comment.parentId;
          if (parentId != null) {
            decrementReplyCount(parentId);
            for (final key in service.commentsBox.keys) {
              if (!key.toString().startsWith('comments_')) continue;
              final list = (service.commentsBox.get(key, defaultValue: []) as List).cast<dynamic>();
              final pIdx = list.indexWhere((c) => c['id'] == parentId || c['\$id'] == parentId);
              if (pIdx != -1) {
                final count = (list[pIdx]['reply_count'] ?? 0) as int;
                list[pIdx] = {
                  ...list[pIdx],
                  'reply_count': count > 0 ? count - 1 : 0,
                };
                service.commentsBox.put(key, list);
              }
            }
          }
          for (final key in service.commentsBox.keys) {
            if (!key.toString().startsWith('comments_')) continue;
            final list = (service.commentsBox.get(key, defaultValue: []) as List).cast<dynamic>();
            final idx = list.indexWhere((c) => c['id'] == id || c['\$id'] == id);
            if (idx != -1) {
              list.removeAt(idx);
              service.commentsBox.put(key, list);
            }
          }
        } else if (event.events.any((e) => e.contains('.update'))) {
          final index = _comments.indexWhere((c) => c.id == id);
          if (index != -1) {
            _comments[index] = comment;
          }
          _likeCounts[id] = comment.likeCount;
          _replyCounts[id] = comment.replyCount;
          for (final key in service.commentsBox.keys) {
            if (!key.toString().startsWith('comments_')) continue;
            final list = (service.commentsBox.get(key, defaultValue: []) as List).cast<dynamic>();
            final idx = list.indexWhere((c) => c['id'] == id || c['\$id'] == id);
            if (idx != -1) {
              list[idx] = {...comment.toJson(), '_cachedAt': DateTime.now().toIso8601String()};
              service.commentsBox.put(key, list);
            }
          }
        }
      }
    });
  }

  void disposeSubscription() {
    _subscription?.close();
    _subscription = null;
  }

  @override
  void onClose() {
    disposeSubscription();
    super.onClose();
  }
}
