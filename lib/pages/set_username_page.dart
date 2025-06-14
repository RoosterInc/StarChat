import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../widgets/responsive_layout.dart';
import '../controllers/master_data_controller.dart';
import '../widgets/complete_enhanced_watchlist.dart';
import '../design_system/modern_ui_system.dart';

class SetUsernamePage extends GetView<AuthController> {
  const SetUsernamePage({super.key});

  MasterDataController get dataController => Get.find<MasterDataController>();

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<MasterDataController>()) {
      Get.put(MasterDataController(), permanent: true);
    }
    return Scaffold(
      appBar: AppBar(title: Text('enter_username'.tr)),
      body: ResponsiveLayout(
        mobile: (_) => _buildForm(context, context.screenWidth * 0.9),
        tablet: (_) => _buildForm(context, 500),
        desktop: (_) => _buildForm(context, 400),
      ),
    );
  }

  Widget _buildForm(BuildContext context, double width) {
    return Center(
      child: Container(
        padding: DesignTokens.md(context).all,
        width: width,
        child: Obx(() => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller.usernameController,
                  decoration: InputDecoration(
                    labelText: 'username'.tr,
                    suffixIcon: controller.usernameText.value.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: controller.clearUsernameInput,
                          )
                        : null,
                ),
                onChanged: controller.onUsernameChanged,
              ),
              SizedBox(height: DesignTokens.md(context)),
              Obx(() => DropdownButtonFormField<RashiOption>(
                    value: dataController.rashiOptions.firstWhereOrNull(
                        (r) => r.rashiId == controller.birthRashiId.value),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Select Rasi',
                    ),
                    items: dataController.rashiOptions
                        .map((r) => DropdownMenuItem(
                              value: r,
                              child: Text('${r.symbol} ${r.name}'),
                            ))
                        .toList(),
                    onChanged: (r) {
                      controller.birthRashiId.value = r?.rashiId ?? '';
                      controller.birthNakshatraId.value = '';
                    },
                  )),
              SizedBox(height: DesignTokens.md(context)),
              Obx(() {
                final options = dataController
                    .getNakshatraForRashi(controller.birthRashiId.value);
                return DropdownButtonFormField<NakshatraOption>(
                  value: options.firstWhereOrNull(
                      (n) => n.nakshatraId == controller.birthNakshatraId.value),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Select Nakshatra',
                  ),
                  items: options
                      .map((n) => DropdownMenuItem(
                            value: n,
                            child: Text('${n.symbol} ${n.name}'),
                          ))
                      .toList(),
                  onChanged: controller.birthRashiId.value.isEmpty
                      ? null
                      : (n) {
                          controller.birthNakshatraId.value =
                              n?.nakshatraId ?? '';
                        },
                );
              }),
              Obx(() => controller.usernameError.value.isEmpty
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: DesignTokens.sm(context).top,
                      child: Text(
                        controller.usernameError.value,
                        style: const TextStyle(color: Colors.red),
                      ),
                    )),
              SizedBox(height: DesignTokens.sm(context)),
              Obx(() {
                  if (!controller.hasCheckedUsername.value) {
                    return const SizedBox.shrink();
                  }
                  if (controller.isCheckingUsername.value) {
                    return SizedBox(
                      width: DesignTokens.spacing(context, 20),
                      height: DesignTokens.spacing(context, 20),
                      child: const CircularProgressIndicator(strokeWidth: 2),
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
                      SizedBox(width: DesignTokens.sm(context)),
                      Text(
                        available ? 'username_available'.tr : 'username_taken'.tr,
                        style: TextStyle(
                          color: available ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  );
                }),
                SizedBox(height: DesignTokens.spacing(context, 20)),
                SizedBox(
                  width: double.infinity,
                  child: Obx(() => AnimatedButton(
                        onPressed: controller.isLoading.value ||
                                !controller.isUsernameValid.value ||
                                !controller.usernameAvailable.value
                            ? null
                            : controller.submitUsername,
                        style: FilledButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: DesignTokens.md(context),
                            vertical: DesignTokens.sm(context),
                          ),
                        ),
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
