import 'package:get/get.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../controllers/auth_controller.dart';
import '../features/notifications/services/notification_service.dart';
import '../features/notifications/controllers/notification_controller.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class NotificationBinding extends Bindings {
  @override
  void dependencies() {
    final auth = Get.find<AuthController>();
    if (!Get.isRegistered<NotificationService>()) {
      Get.put<NotificationService>(
        NotificationService(
          databases: auth.databases,
          databaseId: dotenv.env['APPWRITE_DATABASE_ID'] ?? 'StarChat_DB',
          collectionId:
              dotenv.env['NOTIFICATIONS_COLLECTION_ID'] ?? 'notifications',
          connectivity: Get.put(Connectivity()),
        ),
        permanent: true,
      );
    }
    Get.lazyPut<NotificationController>(() => NotificationController());
  }
}
