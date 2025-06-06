import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/theme_controller.dart';  // Import the ThemeController

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the ThemeController to manage theme changes
    final themeController = Get.put(ThemeController());

    return Scaffold(
      appBar: AppBar(
        title: Text('home_page'.tr),
        actions: [
          // Observe the theme mode and display the appropriate icon
          Obx(() => IconButton(
                icon: Icon(themeController.isDarkMode.value
                    ? Icons.light_mode
                    : Icons.dark_mode),
                onPressed: themeController.toggleTheme, // Toggle the theme on press
              )),
        ],
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(16),
          width: MediaQuery.of(context).size.width * 0.9 > 600
              ? 600
              : MediaQuery.of(context).size.width * 0.9,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'signed_in'.tr,
                style: const TextStyle(fontSize: 24),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  await Get.find<AuthController>().account.deleteSession(sessionId: 'current');
                  Get.find<AuthController>().clearControllers();
                  Get.find<AuthController>().isOTPSent.value = false;
                  Get.offAllNamed('/');
                },
                child: Text('logout'.tr),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Deleted account removal feature for now
}
