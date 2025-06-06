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
      ),
      body: Obx(() {
        return Center(
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(16),
              width: size.width * 0.9 > 400 ? 400 : size.width * 0.9,
              child: controller.isOTPSent.value ? _otpForm() : _emailForm(),
            ),
          ),
        );
      }),
    );
  }

  Widget _emailForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'enter_email'.tr,
          style: const TextStyle(fontSize: 18),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        TextField(
          controller: controller.emailController,
          decoration: InputDecoration(
            labelText: 'email'.tr,
            border: const OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: Obx(() => ElevatedButton(
                onPressed: controller.isLoading.value ? null : controller.sendOTP,
                child: controller.isLoading.value
                    ? const CircularProgressIndicator()
                    : Text('send_otp'.tr),
              )),
        ),
      ],
    );
  }

  Widget _otpForm() {
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
        // Add the 'Change Email' button
        TextButton(
          onPressed: controller.goBackToEmailInput,
          child: Text('change_email'.tr),
        ),
      ],
    );
  }
}