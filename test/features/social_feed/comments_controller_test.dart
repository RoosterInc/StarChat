import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/features/social_feed/controllers/comments_controller.dart';
import 'package:myapp/features/social_feed/models/post_comment.dart';
import 'package:myapp/features/social_feed/models/post_like.dart';
import 'package:myapp/features/social_feed/services/feed_service.dart';
import 'package:myapp/features/profile/services/activity_service.dart';
import 'package:myapp/features/social_feed/models/feed_post.dart';
import 'package:myapp/features/social_feed/controllers/feed_controller.dart';
import 'package:get/get.dart';
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:appwrite/appwrite.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

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

  final List<PostComment> store = [];
  final Map<String, String> likes = {};

  @override
  Future<List<PostComment>> getComments(String postId) async {
    return store.where((c) => c.postId == postId).toList();
  }

  @override
  Future<String?> createComment(PostComment comment) async {
    store.add(comment);
    return null;
  }

  @override
  Future<void> createLike(Map<String, dynamic> like) async {
    likes[like['item_id']] = 'l1';
  }

  @override
  Future<void> likeComment(String commentId, String userId) async {
    likes[commentId] = 'l1';
  }

  @override
  Future<void> unlikeComment(String likeId, String commentId) async {
    likes.removeWhere((key, value) => value == likeId);
  }

  @override
  Future<PostLike?> getUserLike(String itemId, String userId) async {
    final id = likes[itemId];
    return id == null
        ? null
        : PostLike(id: id, itemId: itemId, itemType: 'comment', userId: userId);
  }

  @override
  Future<void> deleteLike(
    String likeId, {
    required String itemId,
    required String itemType,
  }) async {
    likes.removeWhere((key, value) => value == likeId);
  }
}

class OfflineUnlikeService extends FakeFeedService {
  @override
  Future<void> unlikeComment(String likeId, String commentId) {
    return Future.error('offline');
  }
}

class ServiceWithPosts extends FeedService {
  ServiceWithPosts()
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

  final List<FeedPost> posts = [];
  final List<PostComment> comments = [];

  @override
  Future<List<FeedPost>> getPosts(String roomId, {List<String> blockedIds = const []}) async {
    return posts.where((p) => p.roomId == roomId).toList();
  }

  @override
  Future<void> createPost(FeedPost post) async {
    posts.add(post);
  }

  @override
  Future<List<PostComment>> getComments(String postId) async {
    return comments.where((c) => c.postId == postId).toList();
  }

  @override
  Future<String?> createComment(PostComment comment) async {
    comments.add(comment);
    return null;
  }

  @override
  Future<void> deleteComment(String commentId) async {
    comments.removeWhere((c) => c.id == commentId);
  }
}

class RecordingActivityService extends ActivityService {
  final List<String> actions = [];

  RecordingActivityService()
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
  }) async {
    actions.add(actionType);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchActivities(String userId) async {
    return [];
  }
}

void main() {
  test('loadComments returns empty', () async {
    final controller = CommentsController(service: FakeFeedService());
    await controller.loadComments('1');
    expect(controller.comments, isEmpty);
  });

  test('toggleLikeComment updates maps', () async {
    final service = FakeFeedService();
    final controller = CommentsController(service: service);
    final c = PostComment(
      id: '1',
      postId: 'p1',
      userId: 'u',
      username: 'user',
      content: 'hi',
    );
    service.store.add(c);
    await controller.loadComments('p1');
    await controller.toggleLikeComment('1');
    expect(controller.isCommentLiked('1'), isTrue);
    expect(controller.commentLikeCount('1'), 1);
  });

  test('like counts never drop below zero', () async {
    final service = FakeFeedService();
    final controller = CommentsController(service: service);
    final c = PostComment(
      id: '1',
      postId: 'p1',
      userId: 'u',
      username: 'user',
      content: 'hi',
    );
    service.store.add(c);
    service.likes['1'] = 'l1';
    await controller.loadComments('p1');
    await controller.toggleLikeComment('1');
    expect(controller.commentLikeCount('1'), 0);
    await controller.toggleLikeComment('1');
    expect(controller.commentLikeCount('1'), 1);
  });

  test('toggleLikeComment queues unlike when offline', () async {
    final service = OfflineUnlikeService();
    final controller = CommentsController(service: service);
    final c = PostComment(
      id: '1',
      postId: 'p1',
      userId: 'u',
      username: 'user',
      content: 'hi',
      likeCount: 1,
    );
    service.store.add(c);
    service.likes['1'] = 'l1';
    await controller.loadComments('p1');
    await controller.toggleLikeComment('1');
    expect(controller.isCommentLiked('1'), isFalse);
    expect(controller.commentLikeCount('1'), 0);
  });

  test('addComment logs comment activity', () async {
    final dir = await Directory.systemTemp.createTemp();
    Hive.init(dir.path);
    await Hive.openBox('activities');

    Get.testMode = true;
    final activity = RecordingActivityService();
    Get.put<ActivityService>(activity);

    final service = FakeFeedService();
    final controller = CommentsController(service: service);
    final comment = PostComment(
      id: 'c1',
      postId: 'p1',
      userId: 'u1',
      username: 'user',
      content: 'hi',
    );

    await controller.addComment(comment);

    expect(activity.actions, ['comment']);

    await Hive.deleteFromDisk();
    await dir.delete(recursive: true);
    Get.reset();
  });

  test('addComment logs reply activity', () async {
    final dir = await Directory.systemTemp.createTemp();
    Hive.init(dir.path);
    await Hive.openBox('activities');

    Get.testMode = true;
    final activity = RecordingActivityService();
    Get.put<ActivityService>(activity);

    final service = FakeFeedService();
    final controller = CommentsController(service: service);
    final reply = PostComment(
      id: 'c2',
      postId: 'p1',
      parentId: 'c1',
      userId: 'u1',
      username: 'user',
      content: 'reply',
    );

    await controller.addComment(reply);

    expect(activity.actions, ['reply']);

    await Hive.deleteFromDisk();
    await dir.delete(recursive: true);
    Get.reset();
  });

  test('comment count updated in feed controller', () async {
    final service = ServiceWithPosts();
    final feed = FeedController(service: service);
    Get.testMode = true;
    Get.put(feed);
    final post = FeedPost(
      id: 'p1',
      roomId: 'room',
      userId: 'u',
      username: 'poster',
      content: 'hello',
    );
    service.posts.add(post);
    await feed.loadPosts('room');

    final comments = CommentsController(service: service);
    final comment = PostComment(
      id: 'c1',
      postId: 'p1',
      userId: 'c',
      username: 'commenter',
      content: 'hi',
    );
    await comments.addComment(comment);
    expect(feed.postCommentCount('p1'), 1);
    await comments.deleteComment('c1');
    expect(feed.postCommentCount('p1'), 0);
    Get.delete<FeedController>();
  });

  test('replyToComment triggers reply count function', () async {
    final dir = await Directory.systemTemp.createTemp();
    Hive.init(dir.path);
    for (final box in [
      'posts',
      'comments',
      'action_queue',
      'post_queue',
      'bookmarks',
      'hashtags',
      'preferences'
    ]) {
      await Hive.openBox(box);
    }

    final functions = _RecordingFunctions();
    final service = FeedService(
      databases: _FakeDatabases(),
      storage: Storage(Client()),
      functions: functions,
      databaseId: 'db',
      postsCollectionId: 'posts',
      commentsCollectionId: 'comments',
      likesCollectionId: 'likes',
      repostsCollectionId: 'reposts',
      bookmarksCollectionId: 'bookmarks',
      connectivity: Connectivity(),
      linkMetadataFunctionId: 'fetch_link_metadata',
    );

    Get.testMode = true;
    Get.put<ActivityService>(RecordingActivityService());
    final controller = CommentsController(service: service);

    final reply = PostComment(
      id: 'c2',
      postId: 'p1',
      parentId: 'c1',
      userId: 'u',
      username: 'name',
      content: 'reply',
    );

    await controller.replyToComment(reply);
    expect(functions.calls.any((c) => c['id'] == 'increment_reply_count'), isTrue);

    await Hive.deleteFromDisk();
    await dir.delete(recursive: true);
    Get.reset();
  });
}

class _FakeDatabases extends Databases {
  _FakeDatabases() : super(Client());

  @override
  Future<Document> createDocument({
    required String databaseId,
    required String collectionId,
    required String documentId,
    required Map<dynamic, dynamic> data,
    List<String>? permissions,
  }) async {
    return Document.fromMap({
      '\$id': documentId,
      '\$collectionId': collectionId,
      '\$databaseId': databaseId,
      '\$createdAt': '',
      '\$updatedAt': '',
      '\$permissions': [],
      ...data,
    });
  }
}

class _RecordingFunctions extends Functions {
  _RecordingFunctions() : super(Client());

  final List<Map<String, String?>> calls = [];

  @override
  Future<Execution> createExecution({
    required String functionId,
    String? body,
    Map<String, dynamic>? xHeaders,
    String? path,
  }) async {
    calls.add({'id': functionId, 'body': body});
    return Execution.fromMap({
      '\$id': '1',
      '\$createdAt': '',
      '\$updatedAt': '',
      '\$permissions': [],
      'functionId': functionId,
      'trigger': 'http',
      'status': 'completed',
      'requestMethod': 'GET',
      'requestPath': '/',
      'requestHeaders': [],
      'responseStatusCode': 200,
      'responseBody': '',
      'responseHeaders': [],
      'logs': '',
      'errors': '',
      'duration': 0.0,
    });
  }
}
