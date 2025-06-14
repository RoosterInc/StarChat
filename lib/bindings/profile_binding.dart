import 'package:get/get.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../controllers/auth_controller.dart';
import '../features/profile/services/profile_service.dart';
import '../features/profile/controllers/profile_controller.dart';

import '../features/profile/services/activity_service.dart';
import '../features/profile/controllers/activity_controller.dart';
import '../features/profile/controllers/blocked_users_controller.dart';
class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    final auth = Get.find<AuthController>();
    if (!Get.isRegistered<ActivityService>()) {
      Get.lazyPut<ActivityService>(() => ActivityService(
            databases: auth.databases,
            databaseId: dotenv.env['APPWRITE_DATABASE_ID'] ?? 'StarChat_DB',
            collectionId:
                dotenv.env['ACTIVITY_LOGS_COLLECTION_ID'] ?? 'activity_logs',
          ));
    }
    Get.lazyPut<ActivityController>(() => ActivityController(service: Get.find<ActivityService>()));
    Get.lazyPut<ProfileService>(() => ProfileService(
          databases: auth.databases,
          databaseId: dotenv.env['APPWRITE_DATABASE_ID'] ?? 'StarChat_DB',
          profilesCollection: dotenv.env['USER_PROFILES_COLLECTION_ID'] ?? 'user_profiles',
          followsCollection:
              dotenv.env['FOLLOWS_COLLECTION_ID'] ?? 'follows',
          blocksCollection:
              dotenv.env['BLOCKS_COLLECTION_ID'] ?? 'blocked_users',
        ));
    Get.lazyPut<ProfileController>(() => ProfileController());
    Get.lazyPut<BlockedUsersController>(() => BlockedUsersController());
  }
}
