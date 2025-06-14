import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:myapp/features/profile/services/profile_service.dart';
import 'package:myapp/features/notifications/services/notification_service.dart';

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

class _OfflineDatabases extends Databases {
  _OfflineDatabases() : super(Client());

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
  late ProfileService service;
  late _RecordingNotificationService notification;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp();
    Hive.init(dir.path);
    await Hive.openBox('follows');
    await Hive.openBox('notifications');
    await Hive.openBox('notification_queue');
    notification = _RecordingNotificationService();
    Get.put<NotificationService>(notification);
    service = ProfileService(
      databases: _FakeDatabases(),
      databaseId: 'db',
      profilesCollection: 'profiles',
      followsCollection: 'follows',
      blocksCollection: 'blocks',
    );
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await dir.delete(recursive: true);
    Get.reset();
  });

  test('followUser triggers notification creation', () async {
    await service.followUser('u1', 'u2');
    expect(notification.calls, 1);
  });

  test('offline followUser skips notification', () async {
    service = ProfileService(
      databases: _OfflineDatabases(),
      databaseId: 'db',
      profilesCollection: 'profiles',
      followsCollection: 'follows',
      blocksCollection: 'blocks',
    );

    await service.followUser('u1', 'u2');

    expect(notification.calls, 0);
    expect(Hive.box('follows').containsKey('u1_u2'), isTrue);
  });
}
