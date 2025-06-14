import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../controllers/auth_controller.dart';
import '../controllers/theme_controller.dart';
import '../design_system/modern_ui_system.dart';
import '../bindings/profile_binding.dart';
import '../features/profile/screens/blocked_users_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool notifications = true;
  String version = '';

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  Future<void> _loadInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      version = info.version;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    return Scaffold(
      appBar: AppBar(title: Text('settings'.tr)),
      body: ListView(
        children: [
          Obx(() => SwitchListTile(
                title: Text('dark_mode'.tr),
                value: themeController.isDarkMode.value,
                onChanged: (_) => themeController.toggleTheme(),
              )),
          SwitchListTile(
            title: Text('push_notifications'.tr),
            value: notifications,
            onChanged: (v) => setState(() => notifications = v),
          ),
          ListTile(
            title: const Text('Blocked Users'),
            onTap: () => Get.to(() => const BlockedUsersPage(), binding: ProfileBinding()),
          ),
          ListTile(
            title: Text('version'.tr),
            subtitle: Text(version),
          ),
          ListTile(
            title: Text('delete_account'.tr),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('delete_account'.tr),
                  content: Text('delete_account_confirmation'.tr),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text('cancel'.tr),
                    ),
                    AnimatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: DesignTokens.md(context),
                          vertical: DesignTokens.sm(context),
                        ),
                      ),
                      child: Text('delete'.tr),
                    )
                  ],
                ),
              );
              if (confirm ?? false) {
                Get.closeAllSnackbars();
                await Get.find<AuthController>().deleteUserAccount();
              }
            },
          ),
          ListTile(
            title: Text('logout'.tr),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('logout'.tr),
                  content: Text('logout_confirm'.tr),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text('cancel'.tr),
                    ),
                    AnimatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: DesignTokens.md(context),
                          vertical: DesignTokens.sm(context),
                        ),
                      ),
                      child: Text('logout'.tr),
                    )
                  ],
                ),
              );
              if (confirm ?? false) {
                Get.closeAllSnackbars();
                await Get.find<AuthController>().logout();
              }
            },
          ),
        ],
      ),
    );
  }
}
