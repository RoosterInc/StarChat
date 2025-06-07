import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/theme_controller.dart'; // Import the ThemeController
import '../controllers/multi_account_controller.dart';
import '../widgets/responsive_layout.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the ThemeController to manage theme changes
    final themeController = Get.put(ThemeController());

    final authController = Get.find<AuthController>();

    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Obx(
              () => UserAccountsDrawerHeader(
                currentAccountPicture: CircleAvatar(
                  backgroundImage:
                      authController.profilePictureUrl.value.isNotEmpty
                          ? NetworkImage(authController.profilePictureUrl.value)
                          : null,
                  child: authController.profilePictureUrl.value.isEmpty
                      ? const Icon(Icons.person, size: 40)
                      : null,
                ),
                accountName: Text(authController.username.value),
                accountEmail: null,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: Text('profile'.tr),
              onTap: () {
                Navigator.pop(context);
                Get.toNamed('/profile');
              },
            ),
            ListTile(
              leading: const Icon(Icons.switch_account),
              title: Text('manage_accounts'.tr),
              onTap: () {
                Navigator.pop(context);
                Get.toNamed('/accounts');
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: Text('settings'.tr),
              onTap: () {
                Navigator.pop(context);
                Get.toNamed('/settings');
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: Text('home_page'.tr),
        actions: [
          // Observe the theme mode and display the appropriate icon
          Obx(() => IconButton(
                icon: Icon(themeController.isDarkMode.value
                    ? Icons.light_mode
                    : Icons.dark_mode),
                onPressed:
                    themeController.toggleTheme, // Toggle the theme on press
              )),
        ],
      ),
      body: ResponsiveLayout(
        mobile: (_) =>
            _buildContent(context, MediaQuery.of(context).size.width * 0.9),
        tablet: (_) => _buildContent(context, 500),
        desktop: (_) => _buildContent(context, 600),
      ),
    );
  }

  Widget _buildContent(BuildContext context, double width) {
    final authController = Get.find<AuthController>();
    final multi = Get.find<MultiAccountController>();
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Obx(() => Text(
                  'signed_in_as'
                      .trParams({'username': authController.username.value}),
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
            const SizedBox(height: 20),
            Obx(() => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (multi.accounts.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          'saved_accounts'.tr,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ...multi.accounts.map(
                      (a) => ListTile(
                        leading: CircleAvatar(
                          backgroundImage: a.profilePictureUrl.isNotEmpty
                              ? NetworkImage(a.profilePictureUrl)
                              : null,
                          child: a.profilePictureUrl.isEmpty
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        title: Text(a.username),
                        trailing: multi.activeAccountId.value == a.userId
                            ? const Icon(Icons.check)
                            : null,
                        onTap: () async {
                          await multi.switchAccount(a.userId);
                          await authController.checkExistingSession();
                        },
                      ),
                    ),
                  ],
                )),
          ],
        ),
      ),
    );
  }

  // Deleted account removal feature for now
}
