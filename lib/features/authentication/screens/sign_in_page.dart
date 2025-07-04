import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:myapp/core/design_system/modern_ui_system.dart';
import '../../../shared/widgets/animated_form_field.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../controllers/auth_controller.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final AuthController controller = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    controller.resetSignInState();
  }

  @override
  Widget build(BuildContext context) {
    final fromAddAccount = Get.arguments?["fromAddAccount"] ?? false;
    return Scaffold(
      appBar: AppBar(
        leading: fromAddAccount
            ? IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'cancel'.tr,
                onPressed: () => Get.offAllNamed('/accounts'),
              )
            : null,
        title: Text('email_sign_in'.tr),
      ),
      body: ResponsiveLayout(
        mobile: (_) => _buildForm(context, context.screenWidth * 0.9),
        tablet: (_) => _buildForm(context, 500),
        desktop: (_) => _buildForm(context, 400),
      ),
    );
  }

  Widget _buildForm(BuildContext context, double width) {
    return Center(
      child: SingleChildScrollView(
        child: Container(
          padding: DesignTokens.md(context).all,
          width: width,
          child: Obx(
            () => controller.isOTPSent.value ? _otpForm() : _emailForm(),
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
        SizedBox(height: DesignTokens.spacing(context, 20)),
        AnimatedFormField(
          controller: controller.emailController,
          label: 'email'.tr,
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          errorText: controller.emailError.value.isEmpty
              ? null
              : controller.emailError.value,
          onChanged: (_) => controller.emailError.value = '',
        ),
        SizedBox(height: DesignTokens.spacing(context, 20)),
        SizedBox(
          width: double.infinity,
          child: Obx(() => AnimatedButton(
                onPressed:
                    controller.isLoading.value ? null : controller.sendOTP,
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: DesignTokens.md(context),
                    vertical: DesignTokens.sm(context),
                  ),
                ),
                child: controller.isLoading.value
                    ? SkeletonLoader(
                        height: DesignTokens.lg(context),
                        width: DesignTokens.lg(context),
                      )
                    : Text('send_otp'.tr),
              )),
        ),
      ],
    );
  }

  Widget _otpForm() {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          Get.dialog(
            AlertDialog(
              title: const Text('Go Back?'),
              content: const Text('Do you want to go back to email input?'),
              actions: [
                TextButton(
                  onPressed: () {
                    Get.back();
                  },
                  child: Text('cancel'.tr),
                ),
                TextButton(
                  onPressed: () {
                    Get.back();
                    controller.goBackToEmailInput();
                  },
                  child: const Text('Go Back'),
                ),
              ],
            ),
          );
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'enter_otp'.tr,
            style: const TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: DesignTokens.spacing(context, 10)),
          Obx(() => Text(
                'otp_expires_in'.trParams(
                    {'seconds': controller.otpExpiration.value.toString()}),
                style: const TextStyle(color: Colors.red),
              )),
          SizedBox(height: DesignTokens.spacing(context, 10)),
          AnimatedFormField(
            controller: controller.otpController,
            label: 'otp'.tr,
            prefixIcon: Icons.lock_outlined,
            keyboardType: TextInputType.number,
            errorText: controller.otpError.value.isEmpty
                ? null
                : controller.otpError.value,
            onChanged: (_) => controller.otpError.value = '',
          ),
          SizedBox(height: DesignTokens.spacing(context, 20)),
          SizedBox(
            width: double.infinity,
            child: Obx(() => AnimatedButton(
                  onPressed:
                      controller.isLoading.value ? null : controller.verifyOTP,
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: DesignTokens.md(context),
                      vertical: DesignTokens.sm(context),
                    ),
                  ),
                  child: controller.isLoading.value
                      ? SkeletonLoader(
                          height: DesignTokens.lg(context),
                          width: DesignTokens.lg(context),
                        )
                      : Text('verify_otp'.tr),
                )),
          ),
          SizedBox(height: DesignTokens.spacing(context, 10)),
          Obx(() => TextButton(
                onPressed:
                    controller.canResendOTP.value ? controller.resendOTP : null,
                child: controller.canResendOTP.value
                    ? Text('resend_otp'.tr)
                    : Text('resend_otp_in'.trParams({
                        'seconds': controller.resendCooldown.value.toString()
                      })),
              )),
          SizedBox(height: DesignTokens.spacing(context, 10)),
          // Add the 'Change Email' button
          TextButton(
            onPressed: controller.goBackToEmailInput,
            child: Text('change_email'.tr),
          ),
        ],
      ),
    );
  }
}
