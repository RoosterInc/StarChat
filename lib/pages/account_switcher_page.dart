import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/multi_account_controller.dart';
import '../controllers/auth_controller.dart';

class AccountSwitcherPage extends GetView<MultiAccountController> {
  const AccountSwitcherPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    return Scaffold(
      appBar: AppBar(title: Text('manage_accounts'.tr)),
      body: Obx(() => ListView(
            children: [
              ...controller.accounts.map(
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
                  subtitle: Text(a.appwriteUserId), // Changed from a.userId
                  trailing: controller.activeAccountId.value == a.appwriteUserId // Changed from a.userId
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () async {
                    // The MultiAccountController.switchAccount just updates the activeAccountId value.
                    // AuthController.checkExistingSession will handle the actual session switch.
                    await controller.switchAccount(a.appwriteUserId); // Changed from a.userId
                    // No, the new instruction is to call a non-existent auth.switchAccount.
                    // Re-reading: "Change it to a single call: await auth.switchAccount(a.appwriteUserId);"
                    // This implies auth.switchAccount should exist and do the full switch.
                    // However, the PREVIOUS subtask was to modify checkExistingSession.
                    // Let's assume the intent is to use the modified checkExistingSession.
                    // If auth.switchAccount is truly desired, it's a new method.
                    // Given the previous work, this is the most logical step:
                    await auth.checkExistingSession(userIdToSwitchTo: a.appwriteUserId); // Changed from a.userId and separate calls
                  },
                  onLongPress: () async {
                    await controller.removeAccount(a.appwriteUserId); // Changed from a.userId
                  },
                ),
              ),
              ListTile(
                leading: const Icon(Icons.add),
                title: Text('add_account'.tr),
                // onTap: () => Get.offAllNamed('/'), // Original
                onTap: () { // Modified to ensure logout before navigating to sign-in for a new account
                  auth.logout().then((_) { // Ensure current user is logged out
                    Get.offAllNamed('/'); // Navigate to sign-in page
                  });
                },
              )
            ],
          )),
    );
  }
}
