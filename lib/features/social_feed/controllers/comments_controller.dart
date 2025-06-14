import 'dart:math' as math;
import 'package:get/get.dart';
import 'package:appwrite/appwrite.dart';
import '../../../controllers/auth_controller.dart';
import '../models/post_comment.dart';
import "../../profile/services/activity_service.dart";
import '../services/feed_service.dart';
import 'feed_controller.dart';

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

  final _isLoading = false.obs;
  bool get isLoading => _isLoading.value;

  Future<void> loadComments(String postId) async {
    _isLoading.value = true;
    try {
      final data = await service.getComments(postId);
      _comments.assignAll(data);
      _likeCounts.assignAll({for (final c in data) c.id: c.likeCount});
      final auth = Get.find<AuthController>();
      final uid = auth.userId;
      if (uid != null) {
        for (final c in data) {
          final like = await service.getUserLike(c.id, uid);
          if (like != null) _likedIds[c.id] = like.id;
        }
      }
      _listenToRealtime(postId);
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> addComment(PostComment comment) async {
    await service.createComment(comment);
    _comments.add(comment);
    if (comment.parentId == null && Get.isRegistered<FeedController>()) {
      Get.find<FeedController>().incrementCommentCount(comment.postId);
    }
    final action = comment.parentId == null ? 'comment' : 'reply';
    await Get.find<ActivityService>()
        .logActivity(comment.userId, action, itemId: comment.id, itemType: 'comment');
    _likeCounts[comment.id] = comment.likeCount;
  }

  Future<void> replyToComment(PostComment comment) async {
    await addComment(comment);
  }

  Future<void> toggleLikeComment(String commentId) async {
    final auth = Get.find<AuthController>();
    final uid = auth.userId;
    if (uid == null) return;
    if (_likedIds.containsKey(commentId)) {
      final likeId = _likedIds.remove(commentId)!;
      try {
        await service.unlikeComment(likeId, commentId);
      } catch (_) {}
      _likeCounts[commentId] =
          math.max(0, (_likeCounts[commentId] ?? 1) - 1);
    } else {
      await service.likeComment(commentId, uid);
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
    }
  }

  Future<void> deleteComment(PostComment comment) async {
    await service.deleteComment(comment);
    _comments.removeWhere((c) => c.id == comment.id);
    if (comment.parentId == null && Get.isRegistered<FeedController>()) {
      Get.find<FeedController>().decrementCommentCount(comment.postId);
    }
    _likedIds.remove(comment.id);
    _likeCounts.remove(comment.id);
  }

  bool isCommentLiked(String id) => _likedIds.containsKey(id);
  int commentLikeCount(String id) => _likeCounts[id] ?? 0;

  List<PostComment> getReplies(String commentId) {
    return _comments.where((c) => c.parentId == commentId).toList();
  }

  void _listenToRealtime(String postId) {
    if (_postId == postId && _subscription != null) return;
    final auth = Get.find<AuthController>();
    _postId = postId;
    _realtime ??= Realtime(auth.client);
    _subscription?.close();
    _subscription = _realtime!.subscribe([
      'databases.${service.databaseId}.collections.${service.commentsCollectionId}.documents'
    ]);
    _subscription!.stream.listen((event) {
      final payload = event.payload;
      if (payload['post_id'] != postId) return;
      final id = payload['\$id'] ?? payload['id'];
      if (event.events.any((e) => e.contains('.create'))) {
        final comment = PostComment.fromJson(payload);
        if (!_comments.any((c) => c.id == id) && !comment.isDeleted) {
          _comments.add(comment);
          _likeCounts[id] = comment.likeCount;
        }
      } else if (event.events.any((e) => e.contains('.update')) &&
          payload['is_deleted'] == true) {
        _comments.removeWhere((c) => c.id == id);
        _likedIds.remove(id);
        _likeCounts.remove(id);
      }
    });
  }

  @override
  void onClose() {
    _subscription?.close();
    super.onClose();
  }
}
