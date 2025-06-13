import 'package:get/get.dart';
import '../../../controllers/auth_controller.dart';
import '../models/post_comment.dart';
import '../services/feed_service.dart';

class CommentsController extends GetxController {
  final FeedService service;

  CommentsController({required this.service});

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
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> addComment(PostComment comment) async {
    await service.createComment(comment);
    _comments.add(comment);
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
      await service.deleteLike(likeId);
      _likeCounts[commentId] = (_likeCounts[commentId] ?? 1) - 1;
    } else {
      await service.createLike({
        'item_id': commentId,
        'item_type': 'comment',
        'user_id': uid,
      });
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

  bool isCommentLiked(String id) => _likedIds.containsKey(id);
  int commentLikeCount(String id) => _likeCounts[id] ?? 0;
}
