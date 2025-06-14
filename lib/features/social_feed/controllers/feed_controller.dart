import 'package:get/get.dart';
import 'dart:io';
import 'package:hive/hive.dart';
import '../../../controllers/auth_controller.dart';
import '../../profile/services/profile_service.dart';
import '../models/feed_post.dart';
import "../../profile/services/activity_service.dart";
import '../services/feed_service.dart';

class FeedController extends GetxController {
  final FeedService service;

  // Persist user preferences like sorting mode
  final Box _prefs = Hive.box('preferences');

  FeedController({required this.service});

  final _posts = <FeedPost>[].obs;
  List<FeedPost> get posts => _posts;

  final _sortType = 'chronological'.obs;
  String get sortType => _sortType.value;
  set sortType(String value) => _sortType.value = value;

  @override
  void onInit() {
    final saved = _prefs.get('feed_sort_type') as String?;
    if (saved != null) _sortType.value = saved;
    super.onInit();
  }

  /// Update the current sort type and store the preference in Hive.
  void updateSortType(String value) {
    _sortType.value = value;
    _prefs.put('feed_sort_type', value);
  }

  final _likedIds = <String, String>{}.obs; // postId -> likeId
  final _repostedIds = <String, String>{}.obs; // postId -> repostId
  final _likeCounts = <String, int>{}.obs; // postId -> like count
  final _repostCounts = <String, int>{}.obs; // postId -> repost count

  final _isLoading = false.obs;
  bool get isLoading => _isLoading.value;

  List<String> _limitHashtags(List<String> tags) =>
      tags.length > 10 ? tags.sublist(0, 10) : tags;

  Future<void> loadPosts(String roomId, {List<String>? blockedIds}) async {
    _isLoading.value = true;
    try {
      List<String> ids = blockedIds ?? [];
      if (ids.isEmpty &&
          Get.isRegistered<AuthController>() &&
          Get.isRegistered<ProfileService>()) {
        final uid = Get.find<AuthController>().userId;
        if (uid != null) {
          ids = Get.find<ProfileService>().getBlockedIds(uid);
        }
      }
      final data = await service.fetchSortedPosts(_sortType.value, roomId: roomId);
      final filtered = data.where((p) => !ids.contains(p.userId)).toList();
      _posts.assignAll(filtered);
      _likeCounts.assignAll({for (final p in filtered) p.id: p.likeCount});
      _repostCounts.assignAll({for (final p in filtered) p.id: p.repostCount});
      final auth = Get.find<AuthController>();
      final uid = auth.userId;
      if (uid != null) {
        for (final post in filtered) {
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
    await service.createPost(toSave);
    _posts.insert(0, toSave);
  }

  Future<void> createPostWithImage(
    String userId,
    String username,
    String content,
    String roomId,
    File image,
    List<String> hashtags,
    List<String> mentions,
  ) async {
    final limited = _limitHashtags(hashtags);
    await service.createPostWithImage(
      userId,
      username,
      content,
      roomId,
      image,
      hashtags: limited,
      mentions: mentions,
    );
    _posts.insert(
      0,
      FeedPost(
        id: DateTime.now().toIso8601String(),
        roomId: roomId,
        userId: userId,
        username: username,
        content: content,
        mediaUrls: [image.path],
        hashtags: limited,
        mentions: mentions,
      ),
    );
    await Get.find<ActivityService>().logActivity(userId, 'create_post', itemId: _posts.first.id, itemType: 'post');
  }

  Future<void> createPostWithLink(
    String userId,
    String username,
    String content,
    String roomId,
    String linkUrl,
    List<String> hashtags,
    List<String> mentions,
  ) async {
    final metadata = await service.fetchLinkMetadata(linkUrl);
    final limited = _limitHashtags(hashtags);
    await service.createPostWithLink(
      userId,
      username,
      content,
      roomId,
      linkUrl,
      hashtags: limited,
      mentions: mentions,
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
        hashtags: limited,
        mentions: mentions,
      ),
    );
    await Get.find<ActivityService>().logActivity(userId, 'create_post', itemId: _posts.first.id, itemType: 'post');
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

  Future<void> repostPost(String postId, [String? comment]) async {
    final auth = Get.find<AuthController>();
    final uid = auth.userId;
    if (uid == null || _repostedIds.containsKey(postId)) return;
    final id = await service.createRepost({
      'post_id': postId,
      'user_id': uid,
      'comment': comment,
    });
    if (id != null) {
      _repostedIds[postId] = id;
    } else {
      final repost = await service.getUserRepost(postId, uid);
      if (repost != null) _repostedIds[postId] = repost.id;
    }
    _repostCounts[postId] = (_repostCounts[postId] ?? 0) + 1;
  }

  Future<void> undoRepost(String postId) async {
    final auth = Get.find<AuthController>();
    final uid = auth.userId;
    if (uid == null || !_repostedIds.containsKey(postId)) return;
    final repostId = _repostedIds.remove(postId)!;
    await service.deleteRepost(repostId);
    _repostCounts[postId] = (_repostCounts[postId] ?? 1) - 1;
  }

  Future<void> editPost(
    String postId,
    String content,
    List<String> hashtags,
    List<String> mentions,
  ) async {
    final limited = _limitHashtags(hashtags);
    await service.editPost(postId, content, limited, mentions);
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index != -1) {
      final post = _posts[index];
      final newTags =
          limited.where((t) => !post.hashtags.contains(t)).toSet().toList();
      if (newTags.isNotEmpty) {
        await service.saveHashtags(newTags);
      }
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
        hashtags: limited,
        mentions: mentions,
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
