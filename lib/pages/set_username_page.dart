import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../widgets/responsive_layout.dart';

class SetUsernamePage extends GetView<AuthController> {
  const SetUsernamePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('enter_username'.tr)),
      body: ResponsiveLayout(
        mobile: (_) => _buildForm(context, MediaQuery.of(context).size.width * 0.9),
        tablet: (_) => _buildForm(context, 500),
        desktop: (_) => _buildForm(context, 400),
      ),
    );
  }

  Widget _buildForm(BuildContext context, double width) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        width: width,
        child: Obx(() => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller.usernameController,
                  decoration: InputDecoration(
                    labelText: 'username'.tr,
                    suffixIcon: controller.usernameController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: controller.clearUsernameInput,
                          )
                        : null,
                  ),
                  onChanged: controller.onUsernameChanged,
                ),
                const SizedBox(height: 8),
                Obx(() {
                  if (controller.usernameController.text.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  if (controller.isCheckingUsername.value) {
                    return const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    );
                  }
                  final available =
                      controller.isUsernameValid.value && controller.usernameAvailable.value;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        available ? Icons.check : Icons.close,
                        color: available ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        available ? 'username_available'.tr : 'username_taken'.tr,
                        style: TextStyle(
                          color: available ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  );
                }),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: Obx(() => ElevatedButton(
                        onPressed: controller.isLoading.value ||
                                !controller.isUsernameValid.value ||
                                !controller.usernameAvailable.value
                            ? null
                            : controller.submitUsername,
                        child: controller.isLoading.value
                            ? const CircularProgressIndicator()
                            : Text('save'.tr),
                      )),
                ),
              ],
            )),
      ),
    );
  }
}
