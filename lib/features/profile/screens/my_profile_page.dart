import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

import '../../../core/design_system/modern_ui_system.dart';
import '../../../shared/widgets/safe_network_image.dart';
import '../../authentication/controllers/auth_controller.dart';
import '../controllers/user_type_controller.dart';


class MyProfilePage extends GetView<AuthController> {
  const MyProfilePage({super.key});

  Future<void> _changePicture() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final cropped = await ImageCropper().cropImage(sourcePath: picked.path);
    final file = File(cropped?.path ?? picked.path);
    await controller.updateProfilePicture(file);
  }

  Future<void> _changeDisplayName(BuildContext context) async {
    final textController =
        TextEditingController(text: controller.displayName.value);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('display_name'.tr),
        content: TextField(
          controller: textController,
          decoration: InputDecoration(labelText: 'display_name'.tr),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, textController.text.trim()),
            child: Text('save'.tr),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      await controller.updateDisplayName(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userTypeController = Get.find<UserTypeController>();
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
              if (controller.displayName.value.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: DesignTokens.sm(context)),
                  child: Text(controller.displayName.value),
                ),
              const SizedBox(height: 16),
              AnimatedButton(
                onPressed: () => Get.toNamed('/set_username'),
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: DesignTokens.md(context),
                    vertical: DesignTokens.sm(context),
                  ),
                ),
                child: Text('change_username'.tr),
              ),
              const SizedBox(height: 8),
              AnimatedButton(
                onPressed: () => _changeDisplayName(context),
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: DesignTokens.md(context),
                    vertical: DesignTokens.sm(context),
                  ),
                ),
                child: Text('change_displayname'.tr),
              ),
              const SizedBox(height: 8),
              AnimatedButton(
                onPressed: _changePicture,
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: DesignTokens.md(context),
                    vertical: DesignTokens.sm(context),
                  ),
                ),
                child: Text('change_picture'.tr),
              ),
              const SizedBox(height: 16),
              Obx(() => Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('User Type:'),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: userTypeController.userTypeRx.value,
                        items: const [
                          DropdownMenuItem(
                            value: 'General User',
                            child: Text('General User'),
                          ),
                          DropdownMenuItem(
                            value: 'Astrologer',
                            child: Text('Astrologer'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            controller.updateUserType(value);
                          }
                        },
                      ),
                    ],
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
