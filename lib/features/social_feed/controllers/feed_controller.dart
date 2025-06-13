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
    List<String> hashtags,
  ) async {
    await service.createPostWithImage(
        userId, username, content, roomId, image, hashtags);
    _posts.insert(
      0,
      FeedPost(
        id: DateTime.now().toIso8601String(),
        roomId: roomId,
        userId: userId,
        username: username,
        content: content,
        mediaUrls: [image.path],
        hashtags: hashtags,
      ),
    );
  }

  Future<void> createPostWithLink(
    String userId,
    String username,
    String content,
    String roomId,
    String linkUrl,
    List<String> hashtags,
  ) async {
    final metadata = await service.fetchLinkMetadata(linkUrl);
    await service.createPostWithLink(
      userId,
      username,
      content,
      roomId,
      linkUrl,
      hashtags,
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
        hashtags: hashtags,
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

  Future<void> editPost(
    String postId,
    String content,
    List<String> hashtags,
    List<String> mentions,
  ) async {
    await service.editPost(postId, content, hashtags, mentions);
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index != -1) {
      final post = _posts[index];
      _posts[index] = FeedPost(
        id: post.id,
        roomId: post.roomId,
        userId: post.userId,
        username: post.username,
        userAvatar: post.userAvatar,
        content: content,
        mediaUrls: post.mediaUrls,
        pollId: post.pollId,
        linkUrl: post.linkUrl,
        linkMetadata: post.linkMetadata,
        likeCount: post.likeCount,
        commentCount: post.commentCount,
        repostCount: post.repostCount,
        shareCount: post.shareCount,
        hashtags: hashtags,
        isEdited: true,
        editedAt: DateTime.now(),
      );
    }
  }

  Future<void> deletePost(String postId) async {
    await service.deletePost(postId);
    _posts.removeWhere((p) => p.id == postId);
    _likedIds.remove(postId);
    _repostedIds.remove(postId);
    _likeCounts.remove(postId);
    _repostCounts.remove(postId);
  }

  bool isPostLiked(String postId) => _likedIds.containsKey(postId);
  bool isPostReposted(String postId) => _repostedIds.containsKey(postId);
  int postLikeCount(String postId) => _likeCounts[postId] ?? 0;
  int postRepostCount(String postId) => _repostCounts[postId] ?? 0;
}
