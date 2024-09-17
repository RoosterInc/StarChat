import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../themes/app_theme.dart';

class ThemeController extends GetxController {
  // Observing theme mode
  var isDarkMode = false.obs;

  // Toggle between light and dark mode
  void toggleTheme() {
    if (isDarkMode.value) {
      Get.changeTheme(AppTheme.lightTheme);
      isDarkMode.value = false;
    } else {
      Get.changeTheme(AppTheme.darkTheme);
      isDarkMode.value = true;
    }
  }
}
