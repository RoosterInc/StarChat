import 'package:get/get.dart';
import 'dart:io';
import '../../../controllers/auth_controller.dart';
import '../models/feed_post.dart';
import '../services/feed_service.dart';

class FeedController extends GetxController {
  final FeedService service;

  FeedController({required this.service});

  final _posts = <FeedPost>[].obs;
  List<FeedPost> get posts => _posts;

  final _likedIds = <String, String>{}.obs; // postId -> likeId
  final _repostedIds = <String, String>{}.obs; // postId -> repostId
  final _likeCounts = <String, int>{}.obs; // postId -> like count
  final _repostCounts = <String, int>{}.obs; // postId -> repost count

  final _isLoading = false.obs;
  bool get isLoading => _isLoading.value;

  Future<void> loadPosts(String roomId) async {
    _isLoading.value = true;
    try {
      final data = await service.getPosts(roomId);
      _posts.assignAll(data);
      _likeCounts.assignAll({for (final p in data) p.id: p.likeCount});
      _repostCounts.assignAll({for (final p in data) p.id: p.repostCount});
      final auth = Get.find<AuthController>();
      final uid = auth.userId;
      if (uid != null) {
        for (final post in data) {
          final like = await service.getUserLike(post.id, uid);
          if (like != null) _likedIds[post.id] = like.id;
          final repost = await service.getUserRepost(post.id, uid);
          if (repost != null) _repostedIds[post.id] = repost.id;
        }
      }
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> createPost(FeedPost post) async {
    await service.createPost(post);
    _posts.insert(0, post);
  }

  Future<void> createPostWithImage(
    String userId,
    String username,
    String content,
    String roomId,
    File image,
  ) async {
    await service.createPostWithImage(userId, username, content, roomId, image);
    _posts.insert(
      0,
      FeedPost(
        id: DateTime.now().toIso8601String(),
        roomId: roomId,
        userId: userId,
        username: username,
        content: content,
        mediaUrls: [image.path],
      ),
    );
  }

  Future<void> createPostWithLink(
    String userId,
    String username,
    String content,
    String roomId,
    String linkUrl,
    Map<String, dynamic> metadata,
  ) async {
    await service.createPostWithLink(
      userId,
      username,
      content,
      roomId,
      linkUrl,
    );
    _posts.insert(
      0,
      FeedPost(
        id: DateTime.now().toIso8601String(),
        roomId: roomId,
        userId: userId,
        username: username,
        content: content,
        linkUrl: linkUrl,
        linkMetadata: metadata,
      ),
    );
  }

  Future<void> toggleLikePost(String postId) async {
    final auth = Get.find<AuthController>();
    final uid = auth.userId;
    if (uid == null) return;
    if (_likedIds.containsKey(postId)) {
      final likeId = _likedIds.remove(postId)!;
      await service.deleteLike(likeId);
      _likeCounts[postId] = (_likeCounts[postId] ?? 1) - 1;
    } else {
      await service.createLike({
        'item_id': postId,
        'item_type': 'post',
        'user_id': uid,
      });
      final like = await service.getUserLike(postId, uid);
      if (like != null) _likedIds[postId] = like.id;
      _likeCounts[postId] = (_likeCounts[postId] ?? 0) + 1;
    }
  }

  Future<void> repostPost(String postId) async {
    final auth = Get.find<AuthController>();
    final uid = auth.userId;
    if (uid == null || _repostedIds.containsKey(postId)) return;
    await service.createRepost({
      'post_id': postId,
      'user_id': uid,
    });
    final repost = await service.getUserRepost(postId, uid);
    if (repost != null) _repostedIds[postId] = repost.id;
    _repostCounts[postId] = (_repostCounts[postId] ?? 0) + 1;
  }

  bool isPostLiked(String postId) => _likedIds.containsKey(postId);
  bool isPostReposted(String postId) => _repostedIds.containsKey(postId);
  int postLikeCount(String postId) => _likeCounts[postId] ?? 0;
  int postRepostCount(String postId) => _repostCounts[postId] ?? 0;
}
