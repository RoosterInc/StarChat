import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:appwrite/appwrite.dart';
import 'package:myapp/features/social_feed/controllers/feed_controller.dart';
import 'package:myapp/features/social_feed/controllers/comments_controller.dart';
import 'package:myapp/features/social_feed/models/feed_post.dart';
import 'package:myapp/features/social_feed/models/post_comment.dart';
import 'package:myapp/features/social_feed/services/feed_service.dart';
import 'package:myapp/features/profile/services/activity_service.dart';

class SimpleFeedService extends FeedService {
  SimpleFeedService()
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
          linkMetadataFunctionId: 'meta',
        );

  final List<FeedPost> posts = [];
  final List<PostComment> comments = [];

  @override
  Future<List<FeedPost>> fetchSortedPosts(String sortType, {String? roomId}) async {
    return posts.where((p) => roomId == null || p.roomId == roomId).toList();
  }

  @override
  Future<void> createPost(FeedPost post) async {
    posts.add(post);
  }

  @override
  Future<void> createComment(PostComment comment) async {
    comments.add(comment);
  }

  @override
  Future<void> deleteComment(PostComment comment) async {
    comments.removeWhere((c) => c.id == comment.id);
  }

  @override
  Future<List<PostComment>> getComments(String postId) async {
    return comments.where((c) => c.postId == postId).toList();
  }

  @override
  Future<PostLike?> getUserLike(String itemId, String userId) async => null;

  @override
  Future<PostRepost?> getUserRepost(String postId, String userId) async => null;
}

class NoopActivityService extends ActivityService {
  NoopActivityService()
      : super(
          databases: Databases(Client()),
          databaseId: 'db',
          collectionId: 'activities',
        );

  @override
  Future<void> logActivity(String userId, String actionType,
      {String? itemId, String? itemType}) async {}

  @override
  Future<List<Map<String, dynamic>>> fetchActivities(String userId) async => [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('comment count updates when adding and deleting comments', () async {
    final service = SimpleFeedService();
    final feedController = FeedController(service: service);
    final commentsController = CommentsController(service: service);
    Get.put<ActivityService>(NoopActivityService());
    Get.put<FeedController>(feedController);

    final post = FeedPost(
      id: 'p1',
      roomId: 'room',
      userId: 'u1',
      username: 'user',
      content: 'hi',
    );
    service.posts.add(post);
    await feedController.loadPosts('room');

    expect(feedController.postCommentCount('p1'), 0);

    final comment = PostComment(
      id: 'c1',
      postId: 'p1',
      userId: 'u1',
      username: 'user',
      content: 'hello',
    );

    await commentsController.addComment(comment);
    expect(feedController.postCommentCount('p1'), 1);

    await commentsController.deleteComment(comment);
    expect(feedController.postCommentCount('p1'), 0);
  });
}
