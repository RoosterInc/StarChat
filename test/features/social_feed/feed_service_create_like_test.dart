import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:appwrite/enums.dart' as enums;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:myapp/features/social_feed/services/feed_service.dart';
import 'package:myapp/features/notifications/services/notification_service.dart';

class _RecordingFunctions extends Functions {
  _RecordingFunctions() : super(Client());
  String? lastFunctionId;
  @override
  Future<Execution> createExecution({
    required String functionId,
    String? body,
    bool? xasync,
    String? path,
    enums.ExecutionMethod? method,
    Map? headers,
    String? scheduledAt,
  }) async {
    lastFunctionId = functionId;
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

  @override
  Future<Document> getDocument({
    required String databaseId,
    required String collectionId,
    required String documentId,
    List<String>? queries,
  }) async {
    final owner = collectionId == 'comments' ? 'comment_owner' : 'post_owner';
    return Document.fromMap({
      '\$id': documentId,
      '\$collectionId': collectionId,
      '\$databaseId': databaseId,
      '\$createdAt': '',
      '\$updatedAt': '',
      '\$permissions': [],
      'user_id': owner,
    });
  }
}

class _RecordingNotificationService extends NotificationService {
  int calls = 0;
  _RecordingNotificationService()
      : super(
          databases: Databases(Client()),
          databaseId: 'db',
          collectionId: 'notifications',
          connectivity: Connectivity(),
        );
  @override
  Future<void> createNotification(
    String userId,
    String actorId,
    String actionType, {
    String? itemId,
    String? itemType,
  }) async {
    calls++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  late FeedService service;
  late _RecordingNotificationService notification;
  late _RecordingFunctions functions;

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
      'preferences',
      'notifications',
      'notification_queue'
    ]) {
      await Hive.openBox(box);
    }
    functions = _RecordingFunctions();
    notification = _RecordingNotificationService();
    Get.put<NotificationService>(notification);
    service = FeedService(
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
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await dir.delete(recursive: true);
    Get.reset();
  });

  test('createLike on post notifies owner', () async {
    await service.createLike({
      'item_id': 'p1',
      'item_type': 'post',
      'user_id': 'actor',
    });

    expect(functions.lastFunctionId, 'increment_like_count');
    expect(notification.calls, 1);
  });

  test('createLike on comment notifies owner', () async {
    await service.createLike({
      'item_id': 'c1',
      'item_type': 'comment',
      'user_id': 'actor',
    });

    expect(functions.lastFunctionId, 'increment_comment_like_count');
    expect(notification.calls, 1);
  });
}
