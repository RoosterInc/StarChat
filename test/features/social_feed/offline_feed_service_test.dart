import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:myapp/features/social_feed/services/feed_service.dart';
import 'package:myapp/features/social_feed/controllers/comments_controller.dart';
import 'package:get/get.dart';
import 'package:myapp/features/profile/services/activity_service.dart';

class OfflineDatabases extends Databases {
  OfflineDatabases() : super(Client());

  @override
  Future<DocumentList> listDocuments({
    required String databaseId,
    required String collectionId,
    List<String>? queries,
  }) {
    return Future.error('offline');
  }

  @override
  Future<Document> createDocument({
    required String databaseId,
    required String collectionId,
    required String documentId,
    required Map<dynamic, dynamic> data,
    List<String>? permissions,
  }) {
    return Future.error('offline');
  }

  @override
  Future<void> deleteDocument({
    required String databaseId,
    required String collectionId,
    required String documentId,
  }) {
    return Future.error('offline');
  }
}

class OfflineStorage extends Storage {
  OfflineStorage() : super(Client());

  @override
  Future<File> createFile({
    required String bucketId,
    required String fileId,
    required InputFile file,
    List<String>? permissions,
    bool? onProgress,
  }) {
    return Future.error('offline');
  }
}

class _CountingService extends FeedService {
  final List<String> deletedIds = [];
  final List<String> removedBookmarks = [];
  _CountingService()
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

  @override
  Future<void> deleteRepost(String repostId, String postId) async {
    deletedIds.add(repostId);
  }

  @override
  Future<void> removeBookmark(String bookmarkId) async {
    removedBookmarks.add(bookmarkId);
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
  late Directory dir;
  late FeedService service;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp();
    Hive.init(dir.path);
    await Hive.openBox('posts');
    await Hive.openBox('comments');
    await Hive.openBox('action_queue');
    await Hive.openBox('post_queue');
    await Hive.openBox('bookmarks');
    await Hive.openBox('hashtags');
    await Hive.openBox('preferences');
    service = FeedService(
      databases: OfflineDatabases(),
      storage: OfflineStorage(),
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
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await dir.delete(recursive: true);
  });

  test('getPosts returns cached posts when offline', () async {
    final box = Hive.box('posts');
    await box.put('posts_room', [
      {
        'id': '1',
        'room_id': 'room',
        'user_id': 'u',
        'username': 'name',
        'content': 'hi',
        '_cachedAt': DateTime.now().toIso8601String(),
      }
    ]);
    final posts = await service.getPosts('room');
    expect(posts, isNotEmpty);
    expect(posts.first.content, 'hi');
  });

  test('createLike queues when offline', () async {
    await service.createLike({'item_id': '1', 'item_type': 'post', 'user_id': 'u'});
    final queue = Hive.box('action_queue');
    expect(queue.isNotEmpty, isTrue);
  });

  test('createPostWithImage queues when offline', () async {
    final file = File('${dir.path}/img.jpg');
    await file.writeAsBytes(List.filled(10, 0));
    await service.createPostWithImage('u', 'name', 'hi', 'room', file,
        hashtags: ['tag']);
    final queue = Hive.box('post_queue');
    expect(queue.isNotEmpty, isTrue);
  });
  test('createPostWithLink queues when offline', () async {
    await service.createPostWithLink('u', 'name', 'hi', 'room', 'https://x.com',
        hashtags: ['tag']);
    final queue = Hive.box('action_queue');
    expect(queue.isNotEmpty, isTrue);
  });

  test('saveHashtags caches and queues when offline', () async {
    await service.saveHashtags(['tag']);
    final queue = Hive.box('action_queue');
    final box = Hive.box('hashtags');
    expect(queue.isNotEmpty, isTrue);
    final cached = box.get('tag') as Map?;
    expect(cached?['hashtag'], 'tag');
    expect(cached?['last_used_at'], isNotNull);
  });

  test('bookmarkPost queues when offline', () async {
    await service.bookmarkPost('u', '1');
    final queue = Hive.box('action_queue');
    expect(queue.isNotEmpty, isTrue);
  });

  test('removeBookmark queues when offline', () async {
    await expectLater(service.removeBookmark('b1'), throwsA(anything));
    final queue = Hive.box('action_queue');
    expect(queue.isNotEmpty, isTrue);
    final item = queue.getAt(queue.length - 1) as Map?;
    expect(item?['action'], 'remove_bookmark');
    expect(item?['data']['bookmark_id'], 'b1');
  });

  test('postQueueBox capped at 50 items', () async {
    final file = File('${dir.path}/img.jpg');
    await file.writeAsBytes(List.filled(10, 0));
    for (var i = 0; i < 51; i++) {
      await service.createPostWithImage('u', 'name', 'hi', 'room', file);
    }
    final queue = Hive.box('post_queue');
    expect(queue.length, 50);
  });

  test('actionQueue capped at 50 items', () async {
    for (var i = 0; i < 51; i++) {
      await service.createPostWithLink('u', 'name', 'hi', 'room', 'https://x.com');
    }
    final queue = Hive.box('action_queue');
    expect(queue.length, 50);
  });

  test('createComment queues when offline', () async {
    final comment = PostComment(
      id: 'c1',
      postId: 'p1',
      parentId: 'p0',
      userId: 'u',
      username: 'name',
      content: 'hi',
    );
    await service.createComment(comment);
    final queue = Hive.box('action_queue');
    expect(queue.isNotEmpty, isTrue);
    final item = queue.getAt(queue.length - 1) as Map?;
    expect(item?['action'], 'comment');
    expect(item?['data']['id'], 'c1');
  });

  test('deleteLike queues when offline', () async {
    await service.deleteLike('like1', itemId: 'p1', itemType: 'post');
    final queue = Hive.box('action_queue');
    expect(queue.isNotEmpty, isTrue);
    final item = queue.getAt(0) as Map?;
    expect(item?['action'], 'unlike');
    expect(item?['like_id'], 'like1');
  });

  test('deleteRepost queues when offline', () async {
    await expectLater(service.deleteRepost('r1', 'p1'), throwsA(anything));
    final queue = Hive.box('action_queue');
    expect(queue.isNotEmpty, isTrue);
    final item = queue.getAt(queue.length - 1) as Map?;
    expect(item?['action'], 'delete_repost');
    expect(item?['id'], 'r1');
  });

  test('syncQueuedActions processes delete_repost items', () async {
    await expectLater(service.deleteRepost('r2', 'p2'), throwsA(anything));
    final counterService = _CountingService();
    await counterService.syncQueuedActions();
    expect(counterService.deletedIds.contains('r2'), isTrue);
    final queue = Hive.box('action_queue');
    expect(queue.isEmpty, isTrue);
  });

  test('syncQueuedActions processes remove_bookmark items', () async {
    await expectLater(service.removeBookmark('b2'), throwsA(anything));
    final counterService = _CountingService();
    await counterService.syncQueuedActions();
    expect(counterService.removedBookmarks.contains('b2'), isTrue);
    final queue = Hive.box('action_queue');
    expect(queue.isEmpty, isTrue);
  });

  test('syncQueuedActions processes queued reply comments', () async {
    await service.createComment(
      PostComment(
        id: 'c2',
        postId: 'p2',
        parentId: 'c1',
        userId: 'u',
        username: 'name',
        content: 'reply',
      ),
    );
    final functions = _RecordingFunctions();
    final onlineService = FeedService(
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
    await onlineService.syncQueuedActions();
    expect(functions.calls.any((c) => c['id'] == 'increment_reply_count'), isTrue);
    expect(Hive.box('action_queue').isEmpty, isTrue);
  });

  test('offline comment persists across restart', () async {
    final comment = PostComment(
      id: 'c_restart',
      postId: 'p_restart',
      userId: 'u',
      username: 'name',
      content: 'hi',
    );
    await service.createComment(comment);
    expect((Hive.box('comments').get('comments_p_restart') as List).isNotEmpty, isTrue);

    await Hive.close();
    Hive.init(dir.path);
    await Hive.openBox('posts');
    await Hive.openBox('comments');
    await Hive.openBox('action_queue');
    await Hive.openBox('post_queue');
    await Hive.openBox('bookmarks');
    await Hive.openBox('hashtags');
    await Hive.openBox('preferences');

    final newService = FeedService(
      databases: OfflineDatabases(),
      storage: OfflineStorage(),
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

    final comments = await newService.getComments('p_restart');
    expect(comments.length, 1);
    expect(comments.first.id, 'c_restart');
  });

  test('syncQueuedActions removes offline placeholder comments', () async {
    final comment = PostComment(
      id: 'c_sync',
      postId: 'p_sync',
      userId: 'u',
      username: 'name',
      content: 'hi',
    );
    await service.createComment(comment);
    expect((Hive.box('comments').get('comments_p_sync') as List).isNotEmpty, isTrue);

    final onlineService = FeedService(
      databases: _FakeDatabases(),
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
    await onlineService.syncQueuedActions();

    final list = Hive.box('comments').get('comments_p_sync') as List?;
    expect(list == null || list.isEmpty, isTrue);
    expect(Hive.box('comments').containsKey('c_sync'), isFalse);
    expect(Hive.box('action_queue').isEmpty, isTrue);
  });

  test('syncQueuedActions replaces queued comment ids', () async {
    Get.testMode = true;
    Get.put<ActivityService>(DummyActivityService());
    final controller = CommentsController(service: service);
    Get.put(controller);

    final comment = PostComment(
      id: 'tmp1',
      postId: 'p_replace',
      userId: 'u',
      username: 'name',
      content: 'hi',
    );

    await controller.addComment(comment);
    expect(controller.comments.first.id, 'tmp1');
    final queued = Hive.box('action_queue').getAt(
      Hive.box('action_queue').length - 1,
    ) as Map?;
    expect(queued?['data']['id'], 'tmp1');

    final onlineService = FeedService(
      databases: _FakeDatabases(),
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
    await onlineService.syncQueuedActions();

    final list = Hive.box('comments').get('comments_p_replace') as List?;
    expect(list?.length, 1);
    final newId = list!.first['id'] ?? list.first['\$id'];
    expect(newId, isNot('tmp1'));
    expect(controller.comments.length, 1);
    expect(controller.comments.first.id, newId);
    expect(Hive.box('comments').containsKey('tmp1'), isFalse);
    Get.reset();
  });

}
