import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';

class SignInPage extends GetView<AuthController> {
  const SignInPage({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: Text('email_sign_in'.tr),
        actions: [
          // Add clear email button if email is prepopulated
          Obx(() => controller.emailText.value.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: _showClearEmailDialog,
                  tooltip: 'clear_saved_email'.tr,
                )
              : const SizedBox.shrink()),
        ],
      ),
      body: Obx(() {
        // Debug print to see what's happening
        print('🔍 SignInPage build - isOTPSent: ${controller.isOTPSent.value}');
        
        return Center(
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(16),
              width: size.width * 0.9 > 400 ? 400 : size.width * 0.9,
              child: Column(
                children: [
                  // Debug info at the top
                  Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.yellow.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'DEBUG: isOTPSent = ${controller.isOTPSent.value}\n'
                      'isLoading = ${controller.isLoading.value}\n'
                      'Email = "${controller.emailText.value}"',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  
                  // Main content
                  controller.isOTPSent.value ? _buildOtpForm() : _buildEmailForm(),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildEmailForm() {
    print('🔍 Building email form');
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'enter_email'.tr,
          style: const TextStyle(fontSize: 18),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        
        // Show hint if email is prepopulated
        Obx(() => controller.emailText.value.isNotEmpty
            ? _buildSavedEmailHint()
            : const SizedBox.shrink()),
        
        TextField(
          controller: controller.emailController,
          decoration: InputDecoration(
            labelText: 'email'.tr,
            border: const OutlineInputBorder(),
            suffixIcon: controller.emailText.value.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      controller.clearEmailText();
                    },
                  )
                : null,
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        
        const SizedBox(height: 20),
        
        SizedBox(
          width: double.infinity,
          child: Obx(() => ElevatedButton(
                onPressed: controller.isLoading.value ? null : () {
                  print('🔍 Send OTP button pressed');
                  controller.sendOTP();
                },
                child: controller.isLoading.value
                    ? const CircularProgressIndicator()
                    : Text('send_otp'.tr),
              )),
        ),
      ],
    );
  }

  Widget _buildOtpForm() {
    print('🔍 Building OTP form');
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'enter_otp'.tr,
          style: const TextStyle(fontSize: 18),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        
        Obx(() => Text(
              'otp_expires_in'
                  .trParams({'seconds': controller.otpExpiration.value.toString()}),
              style: const TextStyle(color: Colors.red),
            )),
        
        const SizedBox(height: 10),
        
        TextField(
          controller: controller.otpController,
          decoration: InputDecoration(
            labelText: 'otp'.tr,
            border: const OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          maxLength: 6,
        ),
        
        const SizedBox(height: 20),
        
        SizedBox(
          width: double.infinity,
          child: Obx(() => ElevatedButton(
                onPressed: controller.isLoading.value ? null : controller.verifyOTP,
                child: controller.isLoading.value
                    ? const CircularProgressIndicator()
                    : Text('verify_otp'.tr),
              )),
        ),
        
        const SizedBox(height: 10),
        
        Obx(() => TextButton(
              onPressed: controller.canResendOTP.value ? controller.resendOTP : null,
              child: controller.canResendOTP.value
                  ? Text('resend_otp'.tr)
                  : Text('resend_otp_in'.trParams(
                      {'seconds': controller.resendCooldown.value.toString()})),
            )),
        
        const SizedBox(height: 10),
        
        TextButton(
          onPressed: controller.goBackToEmailInput,
          child: Text('change_email'.tr),
        ),
      ],
    );
  }

  Widget _buildSavedEmailHint() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Get.theme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Get.theme.primaryColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Get.theme.primaryColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'using_saved_email'.tr,
              style: TextStyle(
                color: Get.theme.primaryColor,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearEmailDialog() {
    Get.dialog(
      AlertDialog(
        title: Text('clear_saved_email'.tr),
        content: Text('clear_saved_email_confirmation'.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.clearAllData();
            },
            child: Text('clear'.tr),
          ),
        ],
      ),
    );
  }
}