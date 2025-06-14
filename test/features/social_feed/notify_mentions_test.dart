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
    Get.put<NotificationService>(ThrowingNotificationService());
  });

  tearDown(() {
    Get.reset();
  });

  test('notifyMentions handles errors gracefully', () async {
    await notifyMentions(['bob'], '1', itemType: 'post');
  });
}
