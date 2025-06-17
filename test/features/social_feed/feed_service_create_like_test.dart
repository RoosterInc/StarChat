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



class _FakeDatabases extends Databases {
  _FakeDatabases() : super(Client());
  final List<Map<String, dynamic>> updates = [];
  final Map<String, Map<String, dynamic>> docs = {};

  @override
  Future<Document> createDocument({
    required String databaseId,
    required String collectionId,
    required String documentId,
    required Map<dynamic, dynamic> data,
    List<String>? permissions,
  }) async {
    docs[documentId] = Map<String, dynamic>.from(data);
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
    final data = docs[documentId] ?? {};
    return Document.fromMap({
      '\$id': documentId,
      '\$collectionId': collectionId,
      '\$databaseId': databaseId,
      '\$createdAt': '',
      '\$updatedAt': '',
      '\$permissions': [],
      'user_id': owner,
      ...data,
    });
  }

  @override
  Future<Document> updateDocument({
    required String databaseId,
    required String collectionId,
    required String documentId,
    Map<dynamic, dynamic>? data,
    List<String>? permissions,
  }) async {
    updates.add({
      'collectionId': collectionId,
      'documentId': documentId,
      'data': data,
    });
    final existing = docs[documentId] ?? {};
    docs[documentId] = {
      ...existing,
      ...?data,
    };
    return Document.fromMap({
      '\$id': documentId,
      '\$collectionId': collectionId,
      '\$databaseId': databaseId,
      '\$createdAt': '',
      '\$updatedAt': '',
      '\$permissions': [],
      ...docs[documentId]!,
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
  late _FakeDatabases db;

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
    db = _FakeDatabases();
    notification = _RecordingNotificationService();
    Get.put<NotificationService>(notification);
    service = FeedService(
      databases: db,
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
      validateReactionFunctionId: 'validate',
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

    expect(db.updates.last['collectionId'], 'posts');
    expect(db.updates.last['data'], {'like_count': 1});
    expect(notification.calls, 1);
  });

  test('createLike on comment notifies owner', () async {
    await service.createLike({
      'item_id': 'c1',
      'item_type': 'comment',
      'user_id': 'actor',
    });

    expect(db.updates.last['collectionId'], 'comments');
    expect(db.updates.last['data'], {'like_count': 1});
    expect(notification.calls, 1);
  });
}
