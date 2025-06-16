import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:myapp/features/notifications/services/notification_service.dart';
import 'package:myapp/features/social_feed/services/mention_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:myapp/controllers/auth_controller.dart';

class FakeDatabases extends Databases {
  FakeDatabases() : super(Client());

  List<String> _parseNames(String query) {
    final start = query.indexOf('[');
    if (start != -1) {
      final end = query.indexOf(']', start);
      final inside =
          query.substring(start + 1, end).replaceAll('"', '').trim();
      if (inside.isEmpty) return [];
      return inside.split(',').map((e) => e.trim()).toList();
    }
    final match = RegExp(r'"([^"]+)"').firstMatch(query);
    return match != null ? [match.group(1)!] : [];
  }

  @override
  Future<models.DocumentList> listDocuments({
    required String databaseId,
    required String collectionId,
    List<String>? queries,
  }) async {
    final query = queries?.first ?? '';
    final names = _parseNames(query);
    final docs = names
        .map((n) => models.Document.fromMap({
              '\$id': n,
              '\$collectionId': collectionId,
              '\$databaseId': databaseId,
              '\$createdAt': '',
              '\$updatedAt': '',
              '\$permissions': [],
              'username': n,
            }))
        .toList();
    return models.DocumentList(total: docs.length, documents: docs);
  }
}

class CountingDatabases extends FakeDatabases {
  int calls = 0;
  @override
  Future<models.DocumentList> listDocuments({
    required String databaseId,
    required String collectionId,
    List<String>? queries,
  }) async {
    calls++;
    return super.listDocuments(
      databaseId: databaseId,
      collectionId: collectionId,
      queries: queries,
    );
  }
}

class ThrowingNotificationService extends NotificationService {
  ThrowingNotificationService()
      : super(
          databases: Databases(Client()),
          databaseId: 'db',
          collectionId: 'col',
          connectivity: Connectivity(),
        );

  @override
  Future<void> createNotification(String userId, String actorId, String actionType,
      {String? itemId, String? itemType}) async {
    throw Exception('failure');
  }
}

class RecordingNotificationService extends NotificationService {
  int count = 0;
  RecordingNotificationService()
      : super(
          databases: Databases(Client()),
          databaseId: 'db',
          collectionId: 'col',
          connectivity: Connectivity(),
        );
  @override
  Future<void> createNotification(String userId, String actorId, String actionType,
      {String? itemId, String? itemType}) async {
    count++;
  }
}

class FakeAuthController extends AuthController {
  FakeAuthController() {
    account = Account(client);
    databases = FakeDatabases();
    storage = Storage(client);
    userId = 'actor';
  }

  @override
  void onInit() {}
}

class CountingAuthController extends AuthController {
  CountingAuthController(this.db) {
    account = Account(client);
    databases = db;
    storage = Storage(client);
    userId = 'actor';
  }

  final Databases db;

  @override
  void onInit() {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.testMode = true;
    Get.put<AuthController>(FakeAuthController());
    Get.put<NotificationService>(ThrowingNotificationService());
  });

  tearDown(() {
    Get.reset();
  });

  test('notifyMentions handles errors gracefully', () async {
    final service = MentionService(
      databases: Get.find<AuthController>().databases,
      notificationService: Get.find<NotificationService>(),
      databaseId: 'db',
      profilesCollectionId: 'profiles',
    );
    await service.notifyMentions(
      ['bob'],
      '1',
      'post',
    );
  });

  test('notifyMentions sends notification when user found', () async {
    final recorder = RecordingNotificationService();
    Get.put<NotificationService>(recorder);
    final service = MentionService(
      databases: Get.find<AuthController>().databases,
      notificationService: Get.find<NotificationService>(),
      databaseId: 'db',
      profilesCollectionId: 'profiles',
    );
    await service.notifyMentions(
      ['bob'],
      '1',
      'post',
    );
    expect(recorder.count, 1);
  });

  test('notifyMentions queries all names once', () async {
    Get.reset();
    Get.testMode = true;
    final db = CountingDatabases();
    Get.put<AuthController>(CountingAuthController(db));
    final recorder = RecordingNotificationService();
    Get.put<NotificationService>(recorder);
    final service = MentionService(
      databases: db,
      notificationService: Get.find<NotificationService>(),
      databaseId: 'db',
      profilesCollectionId: 'profiles',
    );
    await service.notifyMentions(
      ['bob', 'alice'],
      '1',
      'post',
    );
    expect(db.calls, 1);
    expect(recorder.count, 2);
  });
}
