import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/auth_controller.dart';
import '../../../design_system/modern_ui_system.dart';
import '../controllers/blocked_users_controller.dart';

class BlockedUsersPage extends StatefulWidget {
  const BlockedUsersPage({super.key});

  @override
  State<BlockedUsersPage> createState() => _BlockedUsersPageState();
}

class _BlockedUsersPageState extends State<BlockedUsersPage> {
  @override
  void initState() {
    super.initState();
    final uid = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>().userId
        : null;
    if (uid != null) {
      Get.find<BlockedUsersController>().loadBlockedUsers(uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<BlockedUsersController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Blocked Users')),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Padding(
            padding: EdgeInsets.all(DesignTokens.md(context)),
            child: Column(
              children: List.generate(
                3,
                (_) => Padding(
                  padding: EdgeInsets.only(bottom: DesignTokens.sm(context)),
                  child: SkeletonLoader(
                    height: DesignTokens.xl(context),
                  ),
                ),
              ),
            ),
          );
        }
        return OptimizedListView(
          itemCount: controller.blockedIds.length,
          padding: EdgeInsets.all(DesignTokens.md(context)),
          itemBuilder: (context, index) {
            final id = controller.blockedIds[index];
            return ListTile(
              title: Text(id),
              trailing: AnimatedButton(
                onPressed: () async {
                  await controller.unblock(id);
                },
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: DesignTokens.md(context),
                    vertical: DesignTokens.sm(context),
                  ),
                ),
                child: const Text('Unblock'),
              ),
            );
          },
        );
      }),
    );
  }
}
