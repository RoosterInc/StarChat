import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/profile_controller.dart';
import '../../../controllers/auth_controller.dart';
import '../services/profile_service.dart';
import '../../reports/screens/report_user_page.dart';
import '../../../bindings/report_binding.dart';
import '../../../design_system/modern_ui_system.dart';

class UserProfilePage extends StatefulWidget {
  final String userId;
  const UserProfilePage({super.key, required this.userId});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  @override
  void initState() {
    super.initState();
    Get.find<ProfileController>().loadProfile(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProfileController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        final profile = controller.profile.value;
        if (profile == null) {
          return const Center(child: Text('Profile not found'));
        }
        final authId = Get.find<AuthController>().userId;
        final service = Get.find<ProfileService>();
        final isFollowing = authId != null &&
            service.followsBox.containsKey('${authId}_${profile.id}');
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(profile.username, style: Theme.of(context).textTheme.headlineSmall),
            if (profile.bio != null) Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(profile.bio!),
            ),
            const SizedBox(height: 16),
            AnimatedButton(
              onPressed: () async {
                if (isFollowing) {
                  await controller.unfollowUser(profile.id);
                } else {
                  await controller.followUser(profile.id);
                }
                setState(() {});
              },
              style: FilledButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: DesignTokens.md(context),
                  vertical: DesignTokens.sm(context),
                ),
              ),
              child: Text(isFollowing ? 'Unfollow' : 'Follow'),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: AnimatedButton(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Block User'),
                      content: const Text('Are you sure you want to block this user?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Block'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await controller.blockUser(profile.id);
                  }
                },
                child: const Text('Block'),
              ),
            ),
            if (Get.find<AuthController>().userId != null &&
                Get.find<AuthController>().userId != profile.id)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: AnimatedButton(
                  onPressed: () {
                    Get.to(
                      () => ReportUserPage(userId: profile.id),
                      binding: ReportBinding(),
                    );
                  },
                  child: const Text('Report'),
                ),
              ),
          ],
        );
      }),
    );
  }
}
