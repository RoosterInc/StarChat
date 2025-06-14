import 'package:get/get.dart';
import '../services/profile_service.dart';
import 'profile_controller.dart';

class BlockedUsersController extends GetxController {
  final blockedIds = <String>[].obs;
  final isLoading = false.obs;

  void loadBlockedUsers(String userId) {
    isLoading.value = true;
    try {
      final service = Get.find<ProfileService>();
      blockedIds.assignAll(service.getBlockedIds(userId));
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> unblock(String blockedId) async {
    await Get.find<ProfileController>().unblockUser(blockedId);
    blockedIds.remove(blockedId);
  }
}
