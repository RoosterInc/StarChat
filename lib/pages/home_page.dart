import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/theme_controller.dart';  // Import the ThemeController
import '../widgets/responsive_layout.dart';

const supportedLocales = [
  Locale('en', 'US'),
  Locale('hi', 'IN'),
  Locale('ta', 'IN'),
  Locale('ml', 'IN'),
  Locale('te', 'IN'),
  Locale('kn', 'IN'),
];

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
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'profile'.tr,
            onPressed: () => Get.toNamed('/profile'),
          )
        ],
      ),
      body: ResponsiveLayout(
        mobile: (_) => _buildContent(context, MediaQuery.of(context).size.width * 0.9),
        tablet: (_) => _buildContent(context, 500),
        desktop: (_) => _buildContent(context, 600),
      ),
    );
  }

  Widget _buildContent(BuildContext context, double width) {
    final authController = Get.find<AuthController>();
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButton<Locale>(
              value: Get.locale ?? const Locale('en', 'US'),
              items: [
                for (final locale in supportedLocales)
                  DropdownMenuItem(
                    value: locale,
                    child: Text(locale.languageCode.toUpperCase()),
                  )
              ],
              onChanged: (loc) {
                if (loc != null) {
                  Get.updateLocale(loc);
                }
              },
            ),
            const SizedBox(height: 20),
          Obx(() => Text(
                'signed_in_as'.trParams({'username': authController.username.value}),
                style: const TextStyle(fontSize: 24),
                textAlign: TextAlign.center,
              )),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              Get.closeAllSnackbars();
              await Get.find<AuthController>().logout();
            },
            child: Text('logout'.tr),
          ),
          ],
        ),
      ),
    );
  }

  // Deleted account removal feature for now
}
