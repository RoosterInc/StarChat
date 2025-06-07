import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../widgets/responsive_layout.dart';

const supportedLocales = [
  Locale('en', 'US'),
  Locale('hi', 'IN'),
  Locale('ta', 'IN'),
  Locale('ml', 'IN'),
  Locale('te', 'IN'),
  Locale('kn', 'IN'),
];
class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  Locale _currentLocale = Get.locale ?? const Locale('en', 'US');
  final AuthController controller = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('email_sign_in'.tr),
      ),
      body: ResponsiveLayout(
        mobile: (_) => _buildForm(context, MediaQuery.of(context).size.width * 0.9),
        tablet: (_) => _buildForm(context, 500),
        desktop: (_) => _buildForm(context, 400),
      ),
    );
  }

  Widget _buildForm(BuildContext context, double width) {
    return Center(
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16),
          width: width,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<Locale>(
                value: _currentLocale,
                items: [
                  for (final locale in supportedLocales)
                    DropdownMenuItem(
                      value: locale,
                      child: Text(locale.languageCode.toUpperCase()),
                    )
                ],
                onChanged: (loc) {
                  if (loc != null) {
                    setState(() => _currentLocale = loc);
                    Get.updateLocale(loc);
                  }
                },
              ),
              const SizedBox(height: 20),
              Obx(() => controller.isOTPSent.value ? _otpForm() : _emailForm()),
            ],
          ),
        ),
      ),
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
          onChanged: (_) => controller.emailError.value = '',
        ),
        Obx(() => controller.emailError.value.isEmpty
            ? const SizedBox.shrink()
            : Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  controller.emailError.value,
                  style: const TextStyle(color: Colors.red),
                ),
              )),
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
          onChanged: (_) => controller.otpError.value = '',
        ),
        Obx(() => controller.otpError.value.isEmpty
            ? const SizedBox.shrink()
            : Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  controller.otpError.value,
                  style: const TextStyle(color: Colors.red),
                ),
              )),
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