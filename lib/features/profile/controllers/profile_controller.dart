import 'package:get/get.dart';
import '../models/user_profile.dart';
import '../services/profile_service.dart';
import '../../authentication/controllers/auth_controller.dart';

import '../services/activity_service.dart';
class ProfileController extends GetxController {
  var profile = Rxn<UserProfile>();
  var isLoading = false.obs;
  var isFollowing = false.obs;
  var followerCount = 0.obs;

  Future<void> loadProfile(String userId) async {
    isLoading.value = true;
    try {
      final service = Get.find<ProfileService>();
      profile.value = await service.fetchProfile(userId);
      followerCount.value = await service.getFollowerCount(userId);
      final uid = Get.find<AuthController>().userId;
      if (uid != null) {
        isFollowing.value = await service.isFollowing(uid, userId);
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> followUser(String followedId) async {
    final uid = Get.find<AuthController>().userId;
    if (uid == null) return;
    await Get.find<ProfileService>().followUser(uid, followedId);
    await Get.find<ActivityService>().logActivity(uid, 'follow', itemId: followedId, itemType: 'user');
    if (profile.value?.id == followedId) {
      isFollowing.value = true;
      followerCount.value++;
    }
  }

  Future<void> unfollowUser(String followedId) async {
    final uid = Get.find<AuthController>().userId;
    if (uid == null) return;
    await Get.find<ProfileService>().unfollowUser(uid, followedId);
    await Get.find<ActivityService>().logActivity(
      uid,
      'unfollow',
      itemId: followedId,
      itemType: 'user',
    );
    if (profile.value?.id == followedId) {
      isFollowing.value = false;
      if (followerCount.value > 0) followerCount.value--;
    }
  }

  Future<void> blockUser(String blockedId) async {
    final uid = Get.find<AuthController>().userId;
    if (uid == null) return;
    await Get.find<ProfileService>().blockUser(uid, blockedId);
    await Get.find<ActivityService>().logActivity(uid, 'block_user', itemId: blockedId, itemType: 'user');
  }

  Future<void> unblockUser(String blockedId) async {
    final uid = Get.find<AuthController>().userId;
    if (uid == null) return;
    await Get.find<ProfileService>().unblockUser(uid, blockedId);
    await Get.find<ActivityService>().logActivity(uid, 'unblock_user', itemId: blockedId, itemType: 'user');
  }
}
