import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:appwrite/appwrite.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:appwrite/models.dart' as models;
import 'package:get/get.dart';
import 'package:myapp/features/social_feed/services/feed_service.dart';
import 'package:myapp/features/notifications/services/notification_service.dart';

class RecordingFunctions extends Functions {
  int count = 0;
  RecordingFunctions() : super(Client());
  @override
  Future<models.Execution> createExecution({
    required String functionId,
    String? body,
    bool? xasync,
  }) async {
    count++;
    return models.Execution.fromMap({
      '\$id': 'e1',
      '\$createdAt': '',
      '\$updatedAt': '',
      '\$permissions': [],
      'functionId': functionId,
      'trigger': 'event',
      'status': 'completed',
      'requestMethod': 'POST',
      'requestPath': '',
      'requestHeaders': [],
      'responseStatusCode': 200,
      'responseBody': '',
      'responseHeaders': [],
      'logs': '',
      'errors': '',
      'duration': 0.0,
      'scheduledAt': null,
    });
  }
}

class RecordingNotificationService extends NotificationService {
  int count = 0;
  RecordingNotificationService()
      : super(
          databases: Databases(Client()),
          databaseId: 'db',
          collectionId: 'notifications',
          connectivity: Connectivity(),
        );
  @override
  Future<void> createNotification(String userId, String actorId, String actionType,
      {String? itemId, String? itemType}) async {
    count++;
  }
}

class FakeDatabases extends Databases {
  FakeDatabases() : super(Client());
  bool failCreate = false;
  @override
  Future<models.Document> createDocument({
    required String databaseId,
    required String collectionId,
    required String documentId,
    required Map<dynamic, dynamic> data,
    List<String>? permissions,
  }) async {
    if (failCreate) return Future.error('offline');
    return models.Document.fromMap({
      ...data,
      '\$id': documentId,
      '\$collectionId': collectionId,
      '\$databaseId': databaseId,
      '\$createdAt': '',
      '\$updatedAt': '',
      '\$permissions': [],
    });
  }

  @override
  Future<models.Document> getDocument({
    required String databaseId,
    required String collectionId,
    required String documentId,
  }) async {
    return models.Document.fromMap({
      '\$id': documentId,
      '\$collectionId': collectionId,
      '\$databaseId': databaseId,
      '\$createdAt': '',
      '\$updatedAt': '',
      '\$permissions': [],
      'user_id': 'orig',
    });
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory dir;
  late FeedService service;
  late RecordingFunctions functions;
  late RecordingNotificationService notification;
  late FakeDatabases db;

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
      'notifications',
      'notification_queue'
    ]) {
      await Hive.openBox(box);
    }
    db = FakeDatabases();
    functions = RecordingFunctions();
    notification = RecordingNotificationService();
    Get.put<NotificationService>(notification);
    service = FeedService(
      databases: db,
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
  });

  tearDown(() async {
    Get.reset();
    await Hive.deleteFromDisk();
    await dir.delete(recursive: true);
  });

  test('createRepost triggers function and notification with comment', () async {
    final id = await service.createRepost({
      'post_id': 'p1',
      'user_id': 'u2',
      'comment': 'hi'
    });
    expect(id, isNotNull);
    expect(functions.count, 1);
    expect(notification.count, 1);
  });

  test('createRepost triggers notification without comment', () async {
    final id = await service.createRepost({
      'post_id': 'p1',
      'user_id': 'u2'
    });
    expect(id, isNotNull);
    expect(functions.count, 1);
    expect(notification.count, 1);
  });

  test('syncQueuedActions processes queued reposts and triggers function', () async {
    db.failCreate = true;
    await service.createRepost({'post_id': 'p2', 'user_id': 'u2'});
    expect(functions.count, 0);
    db.failCreate = false;
    await service.syncQueuedActions();
    expect(functions.count, 1);
    expect(Hive.box('action_queue').isEmpty, isTrue);
  });
}
