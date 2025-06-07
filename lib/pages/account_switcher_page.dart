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
                  subtitle: Text(a.userId),
                  trailing: controller.activeAccountId.value == a.userId
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () async {
                    await controller.switchAccount(a.userId);
                    await auth.checkExistingSession();
                  },
                  onLongPress: () async {
                    await controller.removeAccount(a.userId);
                  },
                ),
              ),
              ListTile(
                leading: const Icon(Icons.add),
                title: Text('add_account'.tr),
                onTap: () => Get.offAllNamed(
                  '/',
                  arguments: {'fromAddAccount': true},
                ),
              )
            ],
          )),
    );
  }
}
