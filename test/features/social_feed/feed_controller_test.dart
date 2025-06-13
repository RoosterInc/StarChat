import 'package:flutter_test/flutter_test.dart';
import 'package:appwrite/appwrite.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:myapp/features/social_feed/controllers/feed_controller.dart';
import 'package:myapp/features/social_feed/models/feed_post.dart';
import 'package:myapp/features/social_feed/models/post_like.dart';
import 'package:myapp/features/social_feed/models/post_repost.dart';
import 'package:myapp/features/social_feed/services/feed_service.dart';

class FakeFeedService extends FeedService {
  FakeFeedService()
      : super(
          databases: Databases(Client()),
          databaseId: 'db',
          postsCollectionId: 'posts',
          commentsCollectionId: 'comments',
          likesCollectionId: 'likes',
          repostsCollectionId: 'reposts',
          connectivity: Connectivity(),
        );

  final List<FeedPost> store = [];
  final Map<String, String> likes = {}; // likeId by postId
  final Map<String, String> reposts = {}; // repostId by postId

  @override
  Future<List<FeedPost>> getPosts(String roomId) async {
    return store.where((p) => p.roomId == roomId).toList();
  }

  @override
  Future<void> createPost(FeedPost post) async {
    store.add(post);
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
  Future<void> createRepost(Map<String, dynamic> repost) async {
    reposts[repost['post_id']] = 'r1';
  }

  @override
  Future<PostRepost?> getUserRepost(String postId, String userId) async {
    final id = reposts[postId];
    return id == null
        ? null
        : PostRepost(id: id, postId: postId, userId: userId);
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

  test('repostPost increases count', () async {
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
    expect(controller.postRepostCount('1'), 1);
  });
}
