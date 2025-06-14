import 'package:get/get.dart';
import '../models/user_profile.dart';
import '../services/profile_service.dart';
import '../../../controllers/auth_controller.dart';
import '../services/activity_service.dart';

class ProfileController extends GetxController {
  var profile = Rxn<UserProfile>();
  var isFollowing = false.obs;
  var isLoading = false.obs;

  Future<void> loadProfile(String userId) async {
    isLoading.value = true;
    try {
      profile.value = await Get.find<ProfileService>().fetchProfile(userId);
      final uid = Get.find<AuthController>().userId;
      if (uid != null) {
        isFollowing.value = Get.find<ProfileService>().isFollowing(uid, userId);
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> followUser(String followedId) async {
    final uid = Get.find<AuthController>().userId;
    if (uid == null) return;
    await Get.find<ProfileService>().followUser(uid, followedId);
    isFollowing.value = true;
    await Get.find<ActivityService>()
        .logActivity(uid, 'follow', itemId: followedId, itemType: 'user');
  }

  Future<void> unfollowUser(String unfollowedId) async {
    final uid = Get.find<AuthController>().userId;
    if (uid == null) return;
    await Get.find<ProfileService>().unfollowUser(uid, unfollowedId);
    isFollowing.value = false;
    await Get.find<ActivityService>()
        .logActivity(uid, 'unfollow', itemId: unfollowedId, itemType: 'user');
  }

  Future<void> blockUser(String blockedId) async {
    final uid = Get.find<AuthController>().userId;
    if (uid == null) return;
    await Get.find<ProfileService>().blockUser(uid, blockedId);
    await Get.find<ActivityService>()
        .logActivity(uid, 'block_user', itemId: blockedId, itemType: 'user');
  }

  Future<void> unblockUser(String blockedId) async {
    final uid = Get.find<AuthController>().userId;
    if (uid == null) return;
    await Get.find<ProfileService>().unblockUser(uid, blockedId);
    await Get.find<ActivityService>()
        .logActivity(uid, 'unblock_user', itemId: blockedId, itemType: 'user');
  }
}
