import 'package:flutter_test/flutter_test.dart';
import 'package:appwrite/appwrite.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:io';
import 'package:myapp/features/social_feed/controllers/feed_controller.dart';
import 'package:myapp/features/social_feed/models/feed_post.dart';
import 'package:myapp/features/social_feed/models/post_like.dart';
import 'package:myapp/features/social_feed/models/post_repost.dart';
import 'package:myapp/features/social_feed/services/feed_service.dart';

class FakeFeedService extends FeedService {
  FakeFeedService()
      : super(
          databases: Databases(Client()),
          storage: Storage(Client()),
          functions: Functions(Client()),
          databaseId: 'db',
          postsCollectionId: 'posts',
          commentsCollectionId: 'comments',
          likesCollectionId: 'likes',
          repostsCollectionId: 'reposts',
          connectivity: Connectivity(),
          linkMetadataFunctionId: 'fetch_link_metadata',
        );

  final List<FeedPost> store = [];
  final Map<String, String> likes = {}; // likeId by postId
  final Map<String, String> reposts = {}; // repostId by postId

  @override
  Future<List<FeedPost>> getPosts(String roomId,
      {List<String> blockedIds = const []}) async {
    return store
        .where((p) => p.roomId == roomId && !blockedIds.contains(p.userId))
        .toList();
  }

  @override
  Future<void> createPost(FeedPost post) async {
    store.add(post);
  }

  @override
  Future<void> createPostWithImage(
    String userId,
    String username,
    String content,
    String? roomId,
    File image, {
    List<String> hashtags = const [],
    List<String> mentions = const [],
  }) async {
    store.add(
      FeedPost(
        id: 'img',
        roomId: roomId ?? '',
        userId: userId,
        username: username,
        content: content,
        mediaUrls: [image.path],
        hashtags: hashtags,
        mentions: mentions,
      ),
    );
  }

  @override
  Future<void> createPostWithLink(
    String userId,
    String username,
    String content,
    String? roomId,
    String linkUrl, {
    List<String> hashtags = const [],
    List<String> mentions = const [],
  }) async {
    store.add(
      FeedPost(
        id: 'link',
        roomId: roomId ?? '',
        userId: userId,
        username: username,
        content: content,
        linkUrl: linkUrl,
        hashtags: hashtags,
        mentions: mentions,
      ),
    );
  }

  @override
  Future<void> createLike(Map<String, dynamic> like) async {
    likes[like['item_id']] = 'l1';
  }

  @override
  Future<PostLike?> getUserLike(String itemId, String userId) async {
    final id = likes[itemId];
    return id == null
        ? null
        : PostLike(id: id, itemId: itemId, itemType: 'post', userId: userId);
  }

  @override
  Future<void> deleteLike(String likeId) async {
    likes.removeWhere((key, value) => value == likeId);
  }

  @override
  Future<String?> createRepost(Map<String, dynamic> repost) async {
    reposts[repost['post_id']] = 'r1';
    return 'r1';
  }

  @override
  Future<void> deleteRepost(String repostId) async {
    reposts.removeWhere((key, value) => value == repostId);
  }

  @override
  Future<PostRepost?> getUserRepost(String postId, String userId) async {
    final id = reposts[postId];
    return id == null
        ? null
        : PostRepost(id: id, postId: postId, userId: userId);
  }

  @override
  Future<void> editPost(
      String postId, String content, List<String> hashtags, List<String> mentions) async {
    final index = store.indexWhere((p) => p.id == postId);
    if (index != -1) {
      final p = store[index];
      store[index] = FeedPost(
        id: p.id,
        roomId: p.roomId,
        userId: p.userId,
        username: p.username,
        content: content,
        mediaUrls: p.mediaUrls,
        pollId: p.pollId,
        linkUrl: p.linkUrl,
        linkMetadata: p.linkMetadata,
        likeCount: p.likeCount,
        commentCount: p.commentCount,
        repostCount: p.repostCount,
        shareCount: p.shareCount,
        hashtags: hashtags,
        isEdited: true,
      );
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loadPosts returns empty list', () async {
    final service = FakeFeedService();
    final controller = FeedController(service: service);
    await controller.loadPosts('room');
    expect(controller.posts, isEmpty);
  });

  test('createPost adds to list', () async {
    final service = FakeFeedService();
    final controller = FeedController(service: service);
    final post = FeedPost(
      id: '1',
      roomId: 'room',
      userId: 'u1',
      username: 'user',
      content: 'hello',
    );
    await controller.createPost(post);
    expect(controller.posts.length, 1);
  });

  test('toggleLikePost updates maps', () async {
    final service = FakeFeedService();
    final controller = FeedController(service: service);
    service.store.add(
      FeedPost(
        id: '1',
        roomId: 'room',
        userId: 'u1',
        username: 'user',
        content: 'text',
      ),
    );
    await controller.loadPosts('room');
    await controller.toggleLikePost('1');
    expect(controller.isPostLiked('1'), isTrue);
    expect(controller.postLikeCount('1'), 1);
    await controller.toggleLikePost('1');
    expect(controller.isPostLiked('1'), isFalse);
  });

  test('repostPost stores id and increases count', () async {
    final service = FakeFeedService();
    final controller = FeedController(service: service);
    service.store.add(
      FeedPost(
        id: '1',
        roomId: 'room',
        userId: 'u1',
        username: 'user',
        content: 'hello',
      ),
    );
    await controller.loadPosts('room');
    await controller.repostPost('1', 'nice');
    expect(controller.postRepostCount('1'), 1);
    expect(controller.isPostReposted('1'), isTrue);
  });

  test('undoRepost decreases count', () async {
    final service = FakeFeedService();
    final controller = FeedController(service: service);
    service.store.add(
      FeedPost(
        id: '1',
        roomId: 'room',
        userId: 'u1',
        username: 'user',
        content: 'hello',
      ),
    );
    await controller.loadPosts('room');
    await controller.repostPost('1');
    await controller.undoRepost('1');
    expect(controller.isPostReposted('1'), isFalse);
    expect(controller.postRepostCount('1'), 0);
  });

  test('editPost updates content', () async {
    final service = FakeFeedService();
    final controller = FeedController(service: service);
    final post = FeedPost(
      id: '1',
      roomId: 'room',
      userId: 'u1',
      username: 'user',
      content: 'hello',
    );
    service.store.add(post);
    await controller.loadPosts('room');
    await controller.editPost('1', 'updated', [], []);
    expect(controller.posts.first.content, 'updated');
    expect(controller.posts.first.isEdited, isTrue);
  });

  test('createPost trims hashtags to 10', () async {
    final service = FakeFeedService();
    final controller = FeedController(service: service);
    final tags = List.generate(15, (i) => 'tag$i');
    final post = FeedPost(
      id: '2',
      roomId: 'room',
      userId: 'u2',
      username: 'name',
      content: 'post',
      hashtags: tags,
    );
    await controller.createPost(post);
    expect(service.store.first.hashtags.length, 10);
    expect(controller.posts.first.hashtags.length, 10);
  });

  test('createPostWithImage trims hashtags', () async {
    final dir = await Directory.systemTemp.createTemp();
    final file = File('${dir.path}/img.jpg');
    await file.writeAsBytes(List.filled(10, 0));
    final service = FakeFeedService();
    final controller = FeedController(service: service);
    final tags = List.generate(12, (i) => 't$i');
    await controller.createPostWithImage('u', 'user', 'c', 'room', file, tags, []);
    expect(service.store.first.hashtags.length, 10);
    expect(controller.posts.first.hashtags.length, 10);
    await dir.delete(recursive: true);
  });

  test('createPostWithLink trims hashtags', () async {
    final service = FakeFeedService();
    final controller = FeedController(service: service);
    final tags = List.generate(11, (i) => 'x$i');
    await controller.createPostWithLink(
      'u',
      'user',
      'c',
      'room',
      'https://x.com',
      tags,
      [],
    );
    expect(service.store.first.hashtags.length, 10);
    expect(controller.posts.first.hashtags.length, 10);
  });
}
