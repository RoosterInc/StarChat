import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/user_type_controller.dart';

class UserTypeSwitcher extends StatelessWidget {
  const UserTypeSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final userTypeController = Get.put(UserTypeController());

    return Obx(() {
      return Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
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
              ElevatedButton.icon(
                onPressed: userTypeController.toggleUserType,
                icon: Icon(
                  userTypeController.isAstrologerRx.value
                      ? Icons.person
                      : Icons.stars,
                ),
                label: Text(
                  'Switch to ${userTypeController.isAstrologerRx.value ? "General User" : "Astrologer"}',
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
