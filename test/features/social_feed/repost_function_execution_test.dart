import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:myapp/features/social_feed/services/feed_service.dart';

class RecordingFunctions extends Functions {
  RecordingFunctions() : super(Client());

  String? lastFunctionId;
  String? lastBody;

  @override
  Future<Execution> createExecution({
    required String functionId,
    String? body,
    Map<String, dynamic>? xHeaders,
    String? path,
  }) async {
    lastFunctionId = functionId;
    lastBody = body;
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

class FakeDatabases extends Databases {
  FakeDatabases() : super(Client());

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

  @override
  Future<void> deleteDocument({
    required String databaseId,
    required String collectionId,
    required String documentId,
  }) async {}
}

class OfflineDatabases extends FakeDatabases {
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
}

void main() {
  late Directory dir;
  late RecordingFunctions functions;
  late FeedService service;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp();
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
    functions = RecordingFunctions();
    service = FeedService(
      databases: FakeDatabases(),
      storage: Storage(Client()),
      functions: functions,
      databaseId: 'db',
      postsCollectionId: 'posts',
      commentsCollectionId: 'comments',
      likesCollectionId: 'likes',
      repostsCollectionId: 'reposts',
      bookmarksCollectionId: 'bookmarks',
      connectivity: Connectivity(),
      linkMetadataFunctionId: 'link',
    );
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await dir.delete(recursive: true);
  });

  test('createRepost triggers function execution', () async {
    await service.createRepost({'post_id': '1', 'user_id': 'u'});
    expect(functions.lastFunctionId, 'increment_repost_count');
    expect(functions.lastBody, '{"post_id":"1"}');
  });

  test('deleteRepost triggers decrement function', () async {
    await service.deleteRepost('r1', '1');
    expect(functions.lastFunctionId, 'decrement_repost_count');
    expect(functions.lastBody, '{"post_id":"1"}');
  });

  test('queued repost executes function on sync', () async {
    service = FeedService(
      databases: OfflineDatabases(),
      storage: Storage(Client()),
      functions: functions,
      databaseId: 'db',
      postsCollectionId: 'posts',
      commentsCollectionId: 'comments',
      likesCollectionId: 'likes',
      repostsCollectionId: 'reposts',
      bookmarksCollectionId: 'bookmarks',
      connectivity: Connectivity(),
      linkMetadataFunctionId: 'link',
    );
    await service.createRepost({'post_id': '2', 'user_id': 'u'});
    expect(functions.lastFunctionId, isNull);
    service = FeedService(
      databases: FakeDatabases(),
      storage: Storage(Client()),
      functions: functions,
      databaseId: 'db',
      postsCollectionId: 'posts',
      commentsCollectionId: 'comments',
      likesCollectionId: 'likes',
      repostsCollectionId: 'reposts',
      bookmarksCollectionId: 'bookmarks',
      connectivity: Connectivity(),
      linkMetadataFunctionId: 'link',
    );
    await service.syncQueuedActions();
    expect(functions.lastFunctionId, 'increment_repost_count');
    expect(functions.lastBody, '{"post_id":"2"}');
  });
}
