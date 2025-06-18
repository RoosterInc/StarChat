import 'package:get/get.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../features/authentication/controllers/auth_controller.dart';
import '../features/admin/services/moderation_service.dart';
import '../features/profile/services/activity_service.dart';
import '../features/admin/controllers/moderation_controller.dart';

class ModerationBinding extends Bindings {
  @override
  void dependencies() {
    final auth = Get.find<AuthController>();
    Get.lazyPut<ModerationService>(() => ModerationService(
          databases: auth.databases,
          databaseId: dotenv.env['APPWRITE_DATABASE_ID'] ?? 'StarChat_DB',
        ));
    if (!Get.isRegistered<ActivityService>()) {
      Get.lazyPut<ActivityService>(() => ActivityService(
            databases: auth.databases,
            databaseId: dotenv.env['APPWRITE_DATABASE_ID'] ?? 'StarChat_DB',
            collectionId:
                dotenv.env['ACTIVITY_LOGS_COLLECTION_ID'] ?? 'activity_logs',
          ));
    }
    Get.lazyPut<ModerationController>(() => ModerationController(
          service: Get.find<ModerationService>(),
          activityService: Get.find<ActivityService>(),
        ));
  }
}
