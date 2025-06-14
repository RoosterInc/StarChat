import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:appwrite/appwrite.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:myapp/features/notifications/services/notification_service.dart';
import 'package:myapp/features/social_feed/screens/post_detail_page.dart';
import 'package:myapp/features/social_feed/screens/comment_thread_page.dart';
import 'package:myapp/controllers/auth_controller.dart';

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
  Future<void> createNotification(
    String userId,
    String actorId,
    String actionType, {
    String? itemId,
    String? itemType,
  }) async {
    count++;
  }
}

class FakeAuthController extends AuthController {
  FakeAuthController() {
    account = Account(client);
    databases = Databases(client);
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
    Get.put<NotificationService>(RecordingNotificationService());
  });

  tearDown(() {
    Get.reset();
  });

  test('notifyPostAuthorForTest triggers notification', () async {
    await notifyPostAuthorForTest('owner', 'post');
    final service = Get.find<NotificationService>() as RecordingNotificationService;
    expect(service.count, 1);
  });

  test('notifyParentAuthorForTest triggers notification', () async {
    await notifyParentAuthorForTest('owner', 'comment');
    final service = Get.find<NotificationService>() as RecordingNotificationService;
    expect(service.count, 1);
  });
}
