import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../features/profile/controllers/user_type_controller.dart';
import '../../core/design_system/modern_ui_system.dart';

class UserTypeSwitcher extends StatelessWidget {
  const UserTypeSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final userTypeController = Get.put(UserTypeController());

    return Obx(() {
      return Card(
        margin: DesignTokens.md(context).all,
        child: Padding(
          padding: DesignTokens.md(context).all,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    userTypeController.isAstrologerRx.value
                        ? Icons.stars
                        : Icons.person,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Current User Type: ${userTypeController.userType}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AnimatedButton(
                onPressed: userTypeController.toggleUserType,
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: DesignTokens.md(context),
                    vertical: DesignTokens.sm(context),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      userTypeController.isAstrologerRx.value
                          ? Icons.person
                          : Icons.stars,
                    ),
                    SizedBox(width: DesignTokens.sm(context)),
                    Text(
                      'Switch to ${userTypeController.isAstrologerRx.value ? "General User" : "Astrologer"}',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
