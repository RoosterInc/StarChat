import 'package:get/get.dart';
import 'dart:io';
import 'dart:math' as math;
import 'package:hive/hive.dart';
import 'package:appwrite/appwrite.dart';
import '../../authentication/controllers/auth_controller.dart';
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

  final _pendingPosts = <FeedPost>[];
  final unseenCount = 0.obs;
  bool _initialLoadComplete = false;

  Realtime? _realtime;
  RealtimeSubscription? _subscription;
  String? _roomId;

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
  final _commentCounts = <String, int>{}.obs; // postId -> comment count
  final _bookmarkCount = <String, int>{}.obs; // postId -> bookmark count
  final _shareCounts = <String, int>{}.obs; // postId -> share count

  final _isLoading = false.obs;
  bool get isLoading => _isLoading.value;

  final _isLoadingMore = false.obs;
  bool get isLoadingMore => _isLoadingMore.value;

  String? _nextCursor;

  List<String> _limitHashtags(List<String> tags) =>
      tags.length > 10 ? tags.sublist(0, 10) : tags;

  void _listenToRealtime(String roomId) {
    if (_roomId == roomId && _subscription != null) return;
    final auth = Get.isRegistered<AuthController>() ? Get.find<AuthController>() : null;
    if (auth == null) return;
    _roomId = roomId;
    _realtime ??= Realtime(auth.client);
    _subscription?.close();
    _subscription = _realtime!.subscribe([
      'databases.${service.databaseId}.collections.${service.postsCollectionId}.documents'
    ]);
    _subscription!.stream.listen((event) {
      final payload = event.payload;
      if (payload['room_id'] != _roomId) return;
      final id = payload['\$id'] ?? payload['id'];
      if (event.events.any((e) => e.contains('.create'))) {
        final post = FeedPost.fromJson(payload);
        if (!_posts.any((p) => p.id == id) && !post.isDeleted) {
          if (_initialLoadComplete) {
            _pendingPosts.insert(0, post);
            unseenCount.value = _pendingPosts.length;
          } else {
            _posts.insert(0, post);
          }
          _likeCounts[id] = post.likeCount;
          _repostCounts[id] = post.repostCount;
          _commentCounts[id] = post.commentCount;
          _bookmarkCount[id] = post.bookmarkCount;
          _shareCounts[id] = post.shareCount;
          for (final key in service.postsBox.keys) {
            final cached = service.postsBox.get(key, defaultValue: []) as List;
            cached.insert(
              0,
              {...post.toJson(), '_cachedAt': DateTime.now().toIso8601String()},
            );
            service.postsBox.put(key, cached);
          }
        }
      } else if (event.events.any((e) => e.contains('.update')) ||
          event.events.any((e) => e.contains('.delete'))) {
        final post = FeedPost.fromJson(payload);
        final index = _posts.indexWhere((p) => p.id == id);
        final pendingIndex = _pendingPosts.indexWhere((p) => p.id == id);
        if (post.isDeleted || event.events.any((e) => e.contains('.delete'))) {
          if (index != -1) {
            _posts.removeAt(index);
          }
          if (pendingIndex != -1) {
            _pendingPosts.removeAt(pendingIndex);
            unseenCount.value = _pendingPosts.length;
          }
          _likedIds.remove(id);
          _repostedIds.remove(id);
          _likeCounts.remove(id);
          _repostCounts.remove(id);
          _commentCounts.remove(id);
          _bookmarkCount.remove(id);
          _shareCounts.remove(id);
          for (final key in service.postsBox.keys) {
            final cached = service.postsBox.get(key, defaultValue: []) as List;
            final idx = cached.indexWhere((p) => p['id'] == id || p['\$id'] == id);
            if (idx != -1) {
              cached.removeAt(idx);
              service.postsBox.put(key, cached);
            }
          }
        } else {
          if (index != -1) {
            _posts[index] = post;
          } else if (pendingIndex != -1) {
            _pendingPosts[pendingIndex] = post;
          }
          _likeCounts[id] = post.likeCount;
          _repostCounts[id] = post.repostCount;
          _commentCounts[id] = post.commentCount;
          _bookmarkCount[id] = post.bookmarkCount;
          _shareCounts[id] = post.shareCount;
          for (final key in service.postsBox.keys) {
            final cached = service.postsBox.get(key, defaultValue: []) as List;
            final idx = cached.indexWhere((p) => p['id'] == id || p['\$id'] == id);
            if (idx != -1) {
              cached[idx] = {...post.toJson(), '_cachedAt': DateTime.now().toIso8601String()};
              service.postsBox.put(key, cached);
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

  Future<void> loadPosts(String roomId, {List<String>? blockedIds}) async {
    _isLoading.value = true;
    _nextCursor = null;
    _initialLoadComplete = false;
    _pendingPosts.clear();
    unseenCount.value = 0;
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
      final profileService = Get.isRegistered<ProfileService>()
          ? Get.find<ProfileService>()
          : null;
      final enriched = <FeedPost>[];
      for (final post in filtered) {
        String? avatar = post.userAvatar;
        String? name = post.displayName;
        if (profileService != null && (avatar == null || name == null)) {
          try {
            final profile = await profileService.fetchProfile(post.userId);
            name ??= profile.displayName;
            avatar ??= profile.profilePicture;
          } catch (_) {}
        }
        enriched.add(
          FeedPost(
            id: post.id,
            roomId: post.roomId,
            userId: post.userId,
            username: post.username,
            userAvatar: avatar,
            displayName: name,
            content: post.content,
            mediaUrls: post.mediaUrls,
            pollId: post.pollId,
            linkUrl: post.linkUrl,
            linkMetadata: post.linkMetadata,
            likeCount: post.likeCount,
            commentCount: post.commentCount,
            repostCount: post.repostCount,
            shareCount: post.shareCount,
            hashtags: post.hashtags,
            mentions: post.mentions,
            isEdited: post.isEdited,
            isDeleted: post.isDeleted,
            editedAt: post.editedAt,
            createdAt: post.createdAt,
          ),
        );
      }
      _posts.assignAll(enriched);
      _likeCounts.assignAll({for (final p in enriched) p.id: p.likeCount});
      _repostCounts.assignAll({for (final p in enriched) p.id: p.repostCount});
      _commentCounts.assignAll({for (final p in enriched) p.id: p.commentCount});
      _bookmarkCount.assignAll({for (final p in enriched) p.id: p.bookmarkCount});
      _shareCounts.assignAll({for (final p in enriched) p.id: p.shareCount});
      final auth = Get.find<AuthController>();
      final uid = auth.userId;
      if (uid != null && enriched.isNotEmpty) {
        final ids = enriched.map((p) => p.id).toList();
        final likeMap =
            await service.getUserLikesBulk(ids, uid, itemType: 'post');
        _likedIds.assignAll({
          for (final entry in likeMap.entries) entry.key: entry.value.id
        });
        final repostMap = await service.getUserRepostsBulk(ids, uid);
        _repostedIds.assignAll({
          for (final entry in repostMap.entries) entry.key: entry.value.id
        });
      }
      _listenToRealtime(roomId);
      if (enriched.isNotEmpty) _nextCursor = enriched.last.id;
      _initialLoadComplete = true;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> loadMorePosts() async {
    if (_isLoadingMore.value || _nextCursor == null || _roomId == null) return;
    _isLoadingMore.value = true;
    try {
      List<String> blocked = [];
      if (Get.isRegistered<AuthController>() && Get.isRegistered<ProfileService>()) {
        final uid = Get.find<AuthController>().userId;
        if (uid != null) {
          blocked = Get.find<ProfileService>().getBlockedIds(uid);
        }
      }
      final data = await service.fetchSortedPosts(
        _sortType.value,
        roomId: _roomId,
        cursor: _nextCursor,
      );
      final filtered = data.where((p) => !blocked.contains(p.userId)).toList();
      final profileService = Get.isRegistered<ProfileService>()
          ? Get.find<ProfileService>()
          : null;
      final enriched = <FeedPost>[];
      for (final post in filtered) {
        String? avatar = post.userAvatar;
        String? name = post.displayName;
        if (profileService != null && (avatar == null || name == null)) {
          try {
            final profile = await profileService.fetchProfile(post.userId);
            name ??= profile.displayName;
            avatar ??= profile.profilePicture;
          } catch (_) {}
        }
        enriched.add(
          FeedPost(
            id: post.id,
            roomId: post.roomId,
            userId: post.userId,
            username: post.username,
            userAvatar: avatar,
            displayName: name,
            content: post.content,
            mediaUrls: post.mediaUrls,
            pollId: post.pollId,
            linkUrl: post.linkUrl,
            linkMetadata: post.linkMetadata,
            likeCount: post.likeCount,
            commentCount: post.commentCount,
            repostCount: post.repostCount,
            shareCount: post.shareCount,
            hashtags: post.hashtags,
            mentions: post.mentions,
            isEdited: post.isEdited,
            isDeleted: post.isDeleted,
            editedAt: post.editedAt,
            createdAt: post.createdAt,
          ),
        );
      }
      _posts.addAll(enriched);
      _likeCounts.addAll({for (final p in enriched) p.id: p.likeCount});
      _repostCounts.addAll({for (final p in enriched) p.id: p.repostCount});
      _commentCounts.addAll({for (final p in enriched) p.id: p.commentCount});
      _bookmarkCount.addAll({for (final p in enriched) p.id: p.bookmarkCount});
      _shareCounts.addAll({for (final p in enriched) p.id: p.shareCount});
      final auth = Get.find<AuthController>();
      final uid = auth.userId;
      if (uid != null && enriched.isNotEmpty) {
        final ids = enriched.map((p) => p.id).toList();
        final likeMap =
            await service.getUserLikesBulk(ids, uid, itemType: 'post');
        _likedIds.addAll({
          for (final entry in likeMap.entries) entry.key: entry.value.id
        });
        final repostMap = await service.getUserRepostsBulk(ids, uid);
        _repostedIds.addAll({
          for (final entry in repostMap.entries) entry.key: entry.value.id
        });
      }
      if (data.isNotEmpty) _nextCursor = data.last.id;
    } finally {
      _isLoadingMore.value = false;
    }
  }

  void refreshFeed() {
    if (_pendingPosts.isEmpty) return;
    _posts.insertAll(0, _pendingPosts);
    _likeCounts.addAll({for (final p in _pendingPosts) p.id: p.likeCount});
    _repostCounts.addAll({for (final p in _pendingPosts) p.id: p.repostCount});
    _commentCounts.addAll({for (final p in _pendingPosts) p.id: p.commentCount});
    _bookmarkCount.addAll({for (final p in _pendingPosts) p.id: p.bookmarkCount});
    _shareCounts.addAll({for (final p in _pendingPosts) p.id: p.shareCount});
    _pendingPosts.clear();
    unseenCount.value = 0;
  }

  Future<String> createPost(FeedPost post) async {
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
            createdAt: post.createdAt,
          );
    final id = await service.createPost(toSave) ?? toSave.id;
    final saved = id == toSave.id
        ? toSave
        : FeedPost(
            id: id,
            roomId: toSave.roomId,
            userId: toSave.userId,
            username: toSave.username,
            userAvatar: toSave.userAvatar,
            content: toSave.content,
            mediaUrls: toSave.mediaUrls,
            pollId: toSave.pollId,
            linkUrl: toSave.linkUrl,
            linkMetadata: toSave.linkMetadata,
            likeCount: toSave.likeCount,
            commentCount: toSave.commentCount,
            repostCount: toSave.repostCount,
            shareCount: toSave.shareCount,
            hashtags: toSave.hashtags,
            mentions: toSave.mentions,
            isEdited: toSave.isEdited,
            isDeleted: toSave.isDeleted,
            editedAt: toSave.editedAt,
            createdAt: toSave.createdAt,
          );
    _posts.insert(0, saved);
    _commentCounts[id] = saved.commentCount;
    _bookmarkCount[id] = saved.bookmarkCount;
    _shareCounts[id] = saved.shareCount;
    return id;
  }

  Future<String> createPostWithImage(
    String userId,
    String username,
    String content,
    String roomId,
    File image,
    List<String> hashtags,
    List<String> mentions,
  ) async {
    final limited = _limitHashtags(hashtags);
    final id = await service.createPostWithImage(
      userId,
      username,
      content,
      roomId,
      image,
      hashtags: limited,
      mentions: mentions,
    );
    final now = DateTime.now();
    final newId = id ?? now.toIso8601String();
    _posts.insert(
      0,
      FeedPost(
        id: newId,
        roomId: roomId,
        userId: userId,
        username: username,
        content: content,
        mediaUrls: [image.path],
        hashtags: limited,
        mentions: mentions,
        createdAt: now,
      ),
    );
    _commentCounts[newId] = 0;
    _shareCounts[newId] = 0;
    await Get.find<ActivityService>().logActivity(userId, 'create_post', itemId: _posts.first.id, itemType: 'post');
    return newId;
  }

  Future<String> createPostWithLink(
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
    final id = await service.createPostWithLink(
      userId,
      username,
      content,
      roomId,
      linkUrl,
      hashtags: limited,
      mentions: mentions,
    );
    final now2 = DateTime.now();
    final newId = id ?? now2.toIso8601String();
    _posts.insert(
      0,
      FeedPost(
        id: newId,
        roomId: roomId,
        userId: userId,
        username: username,
        content: content,
        linkUrl: linkUrl,
        linkMetadata: metadata,
        hashtags: limited,
        mentions: mentions,
        createdAt: now2,
      ),
    );
    _commentCounts[newId] = 0;
    _shareCounts[newId] = 0;
    await Get.find<ActivityService>().logActivity(userId, 'create_post', itemId: _posts.first.id, itemType: 'post');
    return newId;
  }

  Future<void> toggleLikePost(String postId) async {
    final auth = Get.find<AuthController>();
    final uid = auth.userId;
    if (uid == null) return;
    final cacheKey = 'like:post_${postId}_$uid';
    if (!_likedIds.containsKey(postId) &&
        service.reactionsBox.containsKey(cacheKey)) {
      return;
    }
    if (_likedIds.containsKey(postId)) {
      final likeId = _likedIds.remove(postId)!;
      try {
        await service.deleteLike(
          likeId,
          itemId: postId,
          itemType: 'post',
        );
        service.reactionsBox.delete(cacheKey);
      } catch (_) {}
      _likeCounts[postId] =
          math.max(0, (_likeCounts[postId] ?? 1) - 1);
    } else {
      final isDup =
          await service.validateReaction('like', postId, uid);
      if (isDup) {
        try {
          final like = await service.getUserLike(postId, uid);
          if (like != null) {
            _likedIds[postId] = like.id;
            service.reactionsBox.put(cacheKey, {
              'itemId': postId,
              'itemType': 'post',
              'userId': uid,
              'likedAt': DateTime.now().toIso8601String(),
            });
          }
        } catch (_) {}
        return;
      }
      await service.createLike({
        'item_id': postId,
        'item_type': 'post',
        'user_id': uid,
      });
      try {
        final like = await service.getUserLike(postId, uid);
        if (like != null) {
          _likedIds[postId] = like.id;
        } else {
          _likedIds[postId] = 'offline';
        }
      } catch (_) {
        _likedIds[postId] = 'offline';
      }
      _likeCounts[postId] = (_likeCounts[postId] ?? 0) + 1;
      service.reactionsBox.put(cacheKey, {
        'itemId': postId,
        'itemType': 'post',
        'userId': uid,
        'likedAt': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> repostPost(String postId, [String? comment]) async {
    final auth = Get.find<AuthController>();
    final uid = auth.userId;
    if (uid == null) return;
    final cacheKey = 'repost:post_${postId}_$uid';
    if (_repostedIds.containsKey(postId) ||
        service.reactionsBox.containsKey(cacheKey)) return;
    final isDup = await service.validateReaction('repost', postId, uid);
    if (isDup) {
      try {
        final r = await service.getUserRepost(postId, uid);
        if (r != null) {
          _repostedIds[postId] = r.id;
          service.reactionsBox.put(cacheKey, {
            'itemId': postId,
            'itemType': 'post',
            'userId': uid,
            'likedAt': DateTime.now().toIso8601String(),
          });
        }
      } catch (_) {}
      return;
    }
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
    service.reactionsBox.put(cacheKey, {
      'itemId': postId,
      'itemType': 'post',
      'userId': uid,
      'likedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> undoRepost(String postId) async {
    final auth = Get.find<AuthController>();
    final uid = auth.userId;
    if (uid == null || !_repostedIds.containsKey(postId)) return;
    final repostId = _repostedIds[postId]!;
    try {
      await service.deleteRepost(repostId, postId);
      _repostedIds.remove(postId);
      _repostCounts[postId] = (_repostCounts[postId] ?? 1) - 1;
      final cacheKey = 'repost:post_${postId}_$uid';
      service.reactionsBox.delete(cacheKey);
    } catch (_) {
      // keep id until synced
    }
  }

  Future<String> sharePost(String postId) async {
    final link = await service.sharePost(postId);
    incrementShareCount(postId);
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index != -1) {
      final post = _posts[index];
      _posts[index] = FeedPost(
        id: post.id,
        roomId: post.roomId,
        userId: post.userId,
        username: post.username,
        userAvatar: post.userAvatar,
        displayName: post.displayName,
        content: post.content,
        mediaUrls: post.mediaUrls,
        pollId: post.pollId,
        linkUrl: post.linkUrl,
        linkMetadata: post.linkMetadata,
        likeCount: post.likeCount,
        commentCount: post.commentCount,
        repostCount: post.repostCount,
        shareCount: postShareCount(postId),
        bookmarkCount: post.bookmarkCount,
        hashtags: post.hashtags,
        mentions: post.mentions,
        isEdited: post.isEdited,
        isDeleted: post.isDeleted,
        editedAt: post.editedAt,
        createdAt: post.createdAt,
      );
    }
    return link;
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
        createdAt: post.createdAt,
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
    _commentCounts.remove(postId);
    _bookmarkCount.remove(postId);
    _shareCounts.remove(postId);
  }

  bool isPostLiked(String postId) => _likedIds.containsKey(postId);
  bool isPostReposted(String postId) => _repostedIds.containsKey(postId);
  int postLikeCount(String postId) => _likeCounts[postId] ?? 0;
  int postRepostCount(String postId) => _repostCounts[postId] ?? 0;
  int postCommentCount(String postId) => _commentCounts[postId] ?? 0;
  int postBookmarkCount(String postId) => _bookmarkCount[postId] ?? 0;
  int postShareCount(String postId) => _shareCounts[postId] ?? 0;

  void incrementBookmarkCount(String postId) {
    _bookmarkCount[postId] = (_bookmarkCount[postId] ?? 0) + 1;
  }

  void decrementBookmarkCount(String postId) {
    _bookmarkCount[postId] =
        math.max(0, (_bookmarkCount[postId] ?? 1) - 1);
  }

  void incrementShareCount(String postId) {
    _shareCounts[postId] = (_shareCounts[postId] ?? 0) + 1;
  }

  void incrementCommentCount(String postId) {
    _commentCounts[postId] = (_commentCounts[postId] ?? 0) + 1;
  }

  void decrementCommentCount(String postId) {
    _commentCounts[postId] = math.max(0, (_commentCounts[postId] ?? 1) - 1);
  }

  void updatePostCounts(FeedPost post) {
    _likeCounts[post.id] = post.likeCount;
    _repostCounts[post.id] = post.repostCount;
    _commentCounts[post.id] = post.commentCount;
    _bookmarkCount[post.id] = post.bookmarkCount;
    _shareCounts[post.id] = post.shareCount;
    final index = _posts.indexWhere((p) => p.id == post.id);
    if (index != -1) {
      _posts[index] = post;
    }
  }

  @override
  void onClose() {
    disposeSubscription();
    super.onClose();
  }
}
