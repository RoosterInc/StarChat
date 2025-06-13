import 'package:get/get.dart';
import '../models/user_profile.dart';
import '../services/profile_service.dart';
import '../../../controllers/auth_controller.dart';

class ProfileController extends GetxController {
  var profile = Rxn<UserProfile>();
  var isLoading = false.obs;

  Future<void> loadProfile(String userId) async {
    isLoading.value = true;
    try {
      profile.value = await Get.find<ProfileService>().fetchProfile(userId);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> followUser(String followedId) async {
    final uid = Get.find<AuthController>().userId;
    if (uid == null) return;
    await Get.find<ProfileService>().followUser(uid, followedId);
  }

  Future<void> blockUser(String blockedId) async {
    final uid = Get.find<AuthController>().userId;
    if (uid == null) return;
    await Get.find<ProfileService>().blockUser(uid, blockedId);
  }

  Future<void> unblockUser(String blockedId) async {
    final uid = Get.find<AuthController>().userId;
    if (uid == null) return;
    await Get.find<ProfileService>().unblockUser(uid, blockedId);
  }
}
