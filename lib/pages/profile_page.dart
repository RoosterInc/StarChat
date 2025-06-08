import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

import '../controllers/auth_controller.dart';
import '../widgets/safe_network_image.dart';

class ProfilePage extends GetView<AuthController> {
  const ProfilePage({super.key});

  Future<void> _changePicture() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final cropped = await ImageCropper().cropImage(sourcePath: picked.path);
    final file = File(cropped?.path ?? picked.path);
    await controller.updateProfilePicture(file);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('profile'.tr),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Get.toNamed('/settings'),
          )
        ],
      ),
      body: Center(
        child: Obx(
          () => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 60,
                child: ClipOval(
                  child: SafeNetworkImage(
                    imageUrl: controller.profilePictureUrl.value,
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                    errorWidget: const Icon(Icons.person, size: 60),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                controller.username.value,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Get.toNamed('/set_username'),
                child: Text('change_username'.tr),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _changePicture,
                child: Text('change_picture'.tr),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
