import 'package:flutter_test/flutter_test.dart';
import 'package:appwrite/appwrite.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import 'package:myapp/features/social_feed/controllers/comments_controller.dart';
import 'package:myapp/features/social_feed/models/post_comment.dart';
import 'package:myapp/features/social_feed/services/feed_service.dart';
import 'package:myapp/features/profile/services/activity_service.dart';

class RecordingFeedService extends FeedService {
  RecordingFeedService()
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

  final List<PostComment> created = [];
  final List<PostComment> deleted = [];
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
    created.add(comment);
    store.add(comment);
    return null;
  }

  @override
  Future<void> deleteComment(PostComment comment) async {
    deleted.add(comment);
    store.removeWhere((c) => c.id == comment.id);
  }
}

class DummyActivityService extends ActivityService {
  DummyActivityService()
      : super(
          databases: Databases(Client()),
          databaseId: 'db',
          collectionId: 'activities',
        );

  @override
  Future<void> logActivity(
    String userId,
    String actionType, {
    String? itemId,
    String? itemType,
  }) async {}

  @override
  Future<List<Map<String, dynamic>>> fetchActivities(String userId) async => [];
}

void main() {
  test('addComment appends to list and calls service', () async {
    Get.testMode = true;
    Get.put<ActivityService>(DummyActivityService());

    final service = RecordingFeedService();
    final controller = CommentsController(service: service);

    final comment = PostComment(
      id: 'c1',
      postId: 'p1',
      userId: 'u1',
      username: 'user',
      content: 'hi',
    );

    await controller.addComment(comment);

    expect(controller.comments.length, 1);
    expect(controller.comments.first.id, 'c1');
    expect(service.created.length, 1);
    expect(service.created.first.id, 'c1');

    Get.reset();
  });

  test('deleteComment removes from list and calls service', () async {
    Get.testMode = true;
    Get.put<ActivityService>(DummyActivityService());

    final service = RecordingFeedService();
    final controller = CommentsController(service: service);

    final comment = PostComment(
      id: 'c1',
      postId: 'p1',
      userId: 'u1',
      username: 'user',
      content: 'hi',
    );
    service.store.add(comment);

    await controller.loadComments('p1');
    await controller.deleteComment('c1');

    expect(controller.comments.isEmpty, isTrue);
    expect(service.deleted.length, 1);
    expect(service.deleted.first.id, 'c1');

    Get.reset();
  });

  test('reply creation increments reply count', () async {
    Get.testMode = true;
    Get.put<ActivityService>(DummyActivityService());

    final service = RecordingFeedService();
    final controller = CommentsController(service: service);

    final parent = PostComment(
      id: 'c1',
      postId: 'p1',
      userId: 'u1',
      username: 'user',
      content: 'hi',
    );
    service.store.add(parent);
    await controller.loadComments('p1');

    final reply = PostComment(
      id: 'c2',
      postId: 'p1',
      parentId: 'c1',
      userId: 'u2',
      username: 'other',
      content: 'reply',
    );

    await controller.replyToComment(reply);

    final updatedParent =
        controller.comments.firstWhere((c) => c.id == 'c1');
    expect(updatedParent.replyCount, 1);

    Get.reset();
  });
}
