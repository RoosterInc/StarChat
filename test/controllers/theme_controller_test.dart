import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:myapp/controllers/theme_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Get.testMode = true;
  });

  test('toggleTheme changes value', () async {
    final controller = ThemeController();
    controller.onInit();
    await Future.delayed(const Duration(milliseconds: 10));
    final initial = controller.isDarkMode.value;
    await controller.toggleTheme();
    expect(controller.isDarkMode.value, isNot(initial));
  });
}
