import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../themes/app_theme.dart';

class ThemeController extends GetxController {
  var isDarkMode = false.obs;
  static const String _themeKey = 'isDarkMode';

  @override
  void onInit() {
    super.onInit();
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getBool(_themeKey) ?? false;
      isDarkMode.value = savedTheme;

      if (savedTheme) {
        Get.changeTheme(AppTheme.darkTheme);
      } else {
        Get.changeTheme(AppTheme.lightTheme);
      }
    } catch (e) {
      print('Error loading theme preference: $e');
    }
  }

  Future<void> toggleTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (isDarkMode.value) {
        Get.changeTheme(AppTheme.lightTheme);
        isDarkMode.value = false;
      } else {
        Get.changeTheme(AppTheme.darkTheme);
        isDarkMode.value = true;
      }

      await prefs.setBool(_themeKey, isDarkMode.value);
    } catch (e) {
      print('Error saving theme preference: $e');
    }
  }
}
