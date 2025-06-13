import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/profile_controller.dart';
import '../../../controllers/auth_controller.dart';
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
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(profile.username, style: Theme.of(context).textTheme.headlineSmall),
            if (profile.bio != null) Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(profile.bio!),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => controller.followUser(profile.id),
              child: const Text('Follow'),
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
