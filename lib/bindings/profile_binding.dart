import 'package:get/get.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../controllers/auth_controller.dart';
import '../features/profile/services/profile_service.dart';
import '../features/profile/controllers/profile_controller.dart';

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    final auth = Get.find<AuthController>();
    Get.lazyPut<ProfileService>(() => ProfileService(
          databases: auth.databases,
          databaseId: dotenv.env['APPWRITE_DATABASE_ID'] ?? 'StarChat_DB',
          profilesCollection: dotenv.env['USER_PROFILES_COLLECTION_ID'] ?? 'user_profiles',
          followsCollection: 'follows',
          blocksCollection: 'blocked_users',
        ));
    Get.lazyPut<ProfileController>(() => ProfileController());
  }
}
