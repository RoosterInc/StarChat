import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../design_system/modern_ui_system.dart';
import '../utils/logger.dart';

class ThemeController extends GetxController {
  var isDarkMode = false.obs;
  final isLoading = false.obs;
  static const String _themeKey = 'isDarkMode';
  static const bool _defaultTheme = false;

  @override
  void onInit() {
    super.onInit();
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    isLoading.value = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getBool(_themeKey);

      if (savedTheme != null) {
        isDarkMode.value = savedTheme;
        logger.i(
            'Theme loaded from preferences: ${savedTheme ? 'dark' : 'light'}');
      } else {
        isDarkMode.value = _defaultTheme;
        await prefs.setBool(_themeKey, _defaultTheme);
        logger.i(
            'First time use - applied default theme: ${_defaultTheme ? 'dark' : 'light'}');
      }

      _applyTheme(isDarkMode.value);
    } on Exception catch (e) {
      logger.e('Error loading theme preference: $e');

      isDarkMode.value = _defaultTheme;
      _applyTheme(_defaultTheme);

      Get.snackbar(
        'Theme Error',
        'Using default theme due to storage error',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
    }
  }

  void _applyTheme(bool isDark) {
    try {
        final newTheme = MD3ThemeSystem.createTheme(
          seedColor: Colors.deepPurple,
          brightness: isDark ? Brightness.dark : Brightness.light,
        );
        Get.changeTheme(newTheme);
      logger.i('Theme applied successfully: ${isDark ? 'dark' : 'light'}');
    } catch (e) {
      logger.e('Error applying theme: $e');
    }
  }

  Future<void> toggleTheme() async {
    isLoading.value = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final newTheme = !isDarkMode.value;

      _applyTheme(newTheme);

      isDarkMode.value = newTheme;

      await prefs.setBool(_themeKey, newTheme);

      logger.i('Theme toggled to: ${newTheme ? 'dark' : 'light'}');
    } on Exception catch (e) {
      logger.e('Error saving theme preference: $e');

      _applyTheme(isDarkMode.value);

      Get.snackbar(
        'Theme Error',
        'Failed to save theme preference',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
    }
  }
}
