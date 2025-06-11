import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class UserTypeController extends GetxController {
  final userType = 'General User'.obs;
  final isAstrologer = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadUserType();
  }

  Future<void> loadUserType() async {
    final prefs = await SharedPreferences.getInstance();
    final savedType = prefs.getString('userType') ?? 'General User';
    userType.value = savedType;
    isAstrologer.value = savedType == 'Astrologer';
  }

  Future<void> updateUserType(String newUserType) async {
    if (!['General User', 'Astrologer'].contains(newUserType)) {
      return;
    }

    userType.value = newUserType;
    isAstrologer.value = newUserType == 'Astrologer';

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userType', newUserType);

    Get.snackbar(
      'Success',
      'User type updated to $newUserType',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.shade100,
      colorText: Colors.green.shade800,
      icon: Icon(Icons.check_circle, color: Colors.green.shade800),
    );
  }

  void toggleUserType() {
    final newType = isAstrologer.value ? 'General User' : 'Astrologer';
    updateUserType(newType);
  }
}
