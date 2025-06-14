import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:myapp/features/social_feed/utils/mention_notifier.dart';
import 'package:myapp/features/notifications/services/notification_service.dart';
import 'package:myapp/controllers/auth_controller.dart';

class FakeDatabases extends Databases {
  FakeDatabases() : super(Client());
  @override
  Future<models.DocumentList> listDocuments({
    required String databaseId,
    required String collectionId,
    List<String>? queries,
  }) async {
    return models.DocumentList(total: 1, documents: [
      models.Document.fromMap({
        '\$id': 'uid',
        '\$collectionId': collectionId,
        '\$databaseId': databaseId,
        '\$createdAt': '',
        '\$updatedAt': '',
        '\$permissions': [],
        'username': 'bob',
      })
    ]);
  }
}

class ThrowingNotificationService extends NotificationService {
  ThrowingNotificationService()
      : super(databases: Databases(Client()), databaseId: 'db', collectionId: 'col');

  @override
  Future<void> createNotification(String userId, String actorId, String actionType,
      {String? itemId, String? itemType}) async {
    throw Exception('failure');
  }
}

class RecordingNotificationService extends NotificationService {
  int count = 0;
  RecordingNotificationService()
      : super(databases: Databases(Client()), databaseId: 'db', collectionId: 'col');

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.testMode = true;
    Get.put<AuthController>(FakeAuthController());
  });

  tearDown(() {
    Get.reset();
  });

  test('notifyMentions handles errors gracefully', () async {
    Get.put<NotificationService>(ThrowingNotificationService());
    await notifyMentions(['bob'], '1', itemType: 'post');
  });

  test('notifyMentions triggers notification', () async {
    final recorder = RecordingNotificationService();
    Get.put<NotificationService>(recorder);
    await notifyMentions(['bob'], '1', itemType: 'post');
    expect(recorder.count, 1);
  });
}
