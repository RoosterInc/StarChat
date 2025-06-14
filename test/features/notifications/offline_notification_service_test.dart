import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:appwrite/appwrite.dart';
import 'package:myapp/features/notifications/services/notification_service.dart';

class OfflineDatabases extends Databases {
  OfflineDatabases() : super(Client());

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
  late NotificationService service;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp();
    Hive.init(dir.path);
    await Hive.openBox('notifications');
    await Hive.openBox('notification_queue');
    service = NotificationService(
      databases: OfflineDatabases(),
      databaseId: 'db',
      collectionId: 'notifications',
    );
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await dir.delete(recursive: true);
  });

  test('createNotification queues when offline', () async {
    await service.createNotification('u', 'a', 'mention');
    final queue = Hive.box('notification_queue');
    expect(queue.isNotEmpty, isTrue);
  });
}
