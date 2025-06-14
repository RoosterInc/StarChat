import 'package:flutter_test/flutter_test.dart';
import 'package:appwrite/appwrite.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:myapp/features/social_feed/controllers/feed_controller.dart';
import 'package:myapp/features/social_feed/models/feed_post.dart';
import 'package:myapp/features/social_feed/models/post_like.dart';
import 'package:myapp/features/social_feed/models/post_repost.dart';
import 'package:myapp/features/social_feed/services/feed_service.dart';

class FakeSortingService extends FeedService {
  FakeSortingService()
      : super(
          databases: Databases(Client()),
          storage: Storage(Client()),
          functions: Functions(Client()),
          databaseId: 'db',
          postsCollectionId: 'posts',
          commentsCollectionId: 'comments',
          likesCollectionId: 'likes',
          repostsCollectionId: 'reposts',
          bookmarksCollectionId: 'bookmarks',
          connectivity: Connectivity(),
          linkMetadataFunctionId: 'fetch_link_metadata',
        );

  List<FeedPost> chronological = [];
  List<FeedPost> mostCommented = [];
  List<FeedPost> mostLiked = [];

  @override
  Future<List<FeedPost>> fetchSortedPosts(String sortType, {String? roomId}) async {
    switch (sortType) {
      case 'chronological':
      case 'most-recent':
        return chronological;
      case 'most-commented':
        return mostCommented;
      case 'most-liked':
        return mostLiked;
    }
    return [];
  }

  @override
  Future<PostLike?> getUserLike(String itemId, String userId) async => null;

  @override
  Future<PostRepost?> getUserRepost(String postId, String userId) async => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('chronological sorting populates posts list in order', () async {
    final service = FakeSortingService();
    final controller = FeedController(service: service);

    service.chronological = [
      FeedPost(
        id: '1',
        roomId: 'room',
        userId: 'u',
        username: 'one',
        content: 'first',
      ),
      FeedPost(
        id: '2',
        roomId: 'room',
        userId: 'u',
        username: 'two',
        content: 'second',
      ),
    ];

    controller.sortType = 'chronological';
    await controller.loadPosts('room');

    expect(controller.posts.map((p) => p.id).toList(), ['1', '2']);
  });

  test('most-commented sorting populates posts list in order', () async {
    final service = FakeSortingService();
    final controller = FeedController(service: service);

    service.mostCommented = [
      FeedPost(
        id: 'a',
        roomId: 'room',
        userId: 'u',
        username: 'x',
        content: 'hi',
        commentCount: 10,
      ),
      FeedPost(
        id: 'b',
        roomId: 'room',
        userId: 'u',
        username: 'y',
        content: 'hello',
        commentCount: 5,
      ),
    ];

    controller.sortType = 'most-commented';
    await controller.loadPosts('room');

    expect(controller.posts.first.commentCount, 10);
    expect(controller.posts[1].commentCount, 5);
  });

  test('most-liked sorting populates posts list in order', () async {
    final service = FakeSortingService();
    final controller = FeedController(service: service);

    service.mostLiked = [
      FeedPost(
        id: 'x',
        roomId: 'room',
        userId: 'u',
        username: 'x',
        content: 'foo',
        likeCount: 2,
      ),
      FeedPost(
        id: 'y',
        roomId: 'room',
        userId: 'u',
        username: 'y',
        content: 'bar',
        likeCount: 1,
      ),
    ];

    controller.sortType = 'most-liked';
    await controller.loadPosts('room');

    expect(controller.posts.first.likeCount, 2);
    expect(controller.posts[1].likeCount, 1);
  });
}

