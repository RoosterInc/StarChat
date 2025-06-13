import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/profile_controller.dart';

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
          ],
        );
      }),
    );
  }
}
