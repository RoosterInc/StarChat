import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:appwrite/appwrite.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:myapp/features/social_feed/controllers/comments_controller.dart';
import 'package:myapp/features/social_feed/controllers/feed_controller.dart';
import 'package:myapp/features/social_feed/models/feed_post.dart';
import 'package:myapp/features/social_feed/models/post_comment.dart';
import 'package:myapp/features/social_feed/services/feed_service.dart';
import 'package:myapp/features/profile/services/activity_service.dart';

class _RecordingFeedService extends FeedService {
  _RecordingFeedService()
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
          validateReactionFunctionId: 'validate',
        );

  final List<PostComment> store = [];

  @override
  Future<List<PostComment>> getComments(
    String postId, {
    int limit = 20,
    String? cursor,
  }) async {
    return store.where((c) => c.postId == postId).toList();
  }

  @override
  Future<String?> createComment(PostComment comment) async {
    store.add(comment);
    return comment.id;
  }

  @override
  Future<void> deleteComment(PostComment comment) async {
    store.removeWhere((c) => c.id == comment.id);
  }
}

class _DummyActivityService extends ActivityService {
  _DummyActivityService()
      : super(databases: Databases(Client()), databaseId: 'db', collectionId: 'act');

  @override
  Future<void> logActivity(String userId, String actionType, {String? itemId, String? itemType}) async {}
}

void main() {
  test('reply add/delete updates counts', () async {
    Get.testMode = true;
    Get.put<ActivityService>(_DummyActivityService());
    final service = _RecordingFeedService();
    final feed = FeedController(service: service);
    Get.put(feed);

    final post = FeedPost(id: 'p1', roomId: 'room', userId: 'u', username: 'user', content: 'post');
    service.store.add(PostComment(id: 'parent', postId: 'p1', userId: 'u', username: 'user', content: 'parent'));
    await feed.loadPosts('room');
    expect(feed.postCommentCount('p1'), 0);
    final controller = CommentsController(service: service);
    await controller.loadComments('p1');

    final reply = PostComment(id: 'r1', postId: 'p1', parentId: 'parent', userId: 'u2', username: 'other', content: 'hi');
    await controller.addComment(reply);
    expect(feed.postCommentCount('p1'), 1);
    expect(controller.comments.firstWhere((c) => c.id == 'parent').replyCount, 1);

    await controller.deleteComment('r1');
    expect(feed.postCommentCount('p1'), 0);
    expect(controller.comments.firstWhere((c) => c.id == 'parent').replyCount, 0);

    Get.reset();
  });
}
