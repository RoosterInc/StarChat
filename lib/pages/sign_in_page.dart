// lib/pages/sign_in_page.dart
// Completely modernized sign-in page with glassmorphism and animations

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../design_system/modern_ui_system.dart';
import 'dart:ui';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage>
    with TickerProviderStateMixin {
  final AuthController controller = Get.find<AuthController>();
  late AnimationController _backgroundController;
  late AnimationController _formController;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _formSlideAnimation;
  late Animation<double> _formFadeAnimation;

  @override
  void initState() {
    super.initState();
    controller.resetSignInState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _formController = AnimationController(
      duration: DesignTokens.durationNormal,
      vsync: this,
    );

    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.linear,
    ));

    _formSlideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _formController,
      curve: DesignTokens.curveEaseOut,
    ));

    _formFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _formController,
      curve: DesignTokens.curveEaseOut,
    ));

    _backgroundController.repeat();
    _formController.forward();
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _formController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fromAddAccount = Get.arguments?["fromAddAccount"] ?? false;

    return Scaffold(
      body: Stack(
        children: [
          _buildAnimatedBackground(context),
          _buildContent(context, fromAddAccount),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground(BuildContext context) {
    return AnimatedBuilder(
      animation: _backgroundAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                context.colorScheme.primary.withOpacity(0.8),
                context.colorScheme.secondary.withOpacity(0.6),
                context.colorScheme.tertiary.withOpacity(0.4),
              ],
              transform: GradientRotation(_backgroundAnimation.value * 2 * 3.14159),
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 100 + (_backgroundAnimation.value * 20),
                left: 50 + (_backgroundAnimation.value * 30),
                child: _buildFloatingCircle(80, Colors.white.withOpacity(0.1)),
              ),
              Positioned(
                top: 300 + (_backgroundAnimation.value * -25),
                right: 30 + (_backgroundAnimation.value * 20),
                child: _buildFloatingCircle(120, Colors.white.withOpacity(0.05)),
              ),
              Positioned(
                bottom: 200 + (_backgroundAnimation.value * 15),
                left: 20 + (_backgroundAnimation.value * -10),
                child: _buildFloatingCircle(60, Colors.white.withOpacity(0.08)),
              ),
              Positioned(
                bottom: 100 + (_backgroundAnimation.value * 30),
                right: 80 + (_backgroundAnimation.value * -20),
                child: _buildFloatingCircle(100, Colors.white.withOpacity(0.06)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFloatingCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool fromAddAccount) {
    return SafeArea(
      child: AnimatedBuilder(
        animation: _formController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _formSlideAnimation.value),
            child: Opacity(
              opacity: _formFadeAnimation.value,
              child: Column(
                children: [
                  _buildAppBar(context, fromAddAccount),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: ResponsiveUtils.adaptiveValue(
                          context,
                          mobile: DesignTokens.lg(context).all,
                          tablet: EdgeInsets.symmetric(
                            horizontal: MediaQuery.of(context).size.width * 0.2,
                            vertical: DesignTokens.lg(context),
                          ),
                          desktop: EdgeInsets.symmetric(
                            horizontal: MediaQuery.of(context).size.width * 0.3,
                            vertical: DesignTokens.xl(context),
                          ),
                        ),
                        child: _buildMainCard(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool fromAddAccount) {
    if (!fromAddAccount) return const SizedBox.shrink();

    return Padding(
      padding: DesignTokens.md(context).all,
      child: Row(
        children: [
          AnimatedButton(
            onPressed: () => Get.offAllNamed('/accounts'),
            child: GlassmorphicContainer(
              padding: DesignTokens.sm(context).all,
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd(context)),
              child: Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainCard(BuildContext context) {
    return GlassmorphicContainer(
      padding: ResponsiveUtils.adaptiveValue(
        context,
        mobile: DesignTokens.xl(context).all,
        tablet: DesignTokens.xxl(context).all,
        desktop: DesignTokens.xxl(context).all,
      ),
      borderRadius: BorderRadius.circular(DesignTokens.radiusXl(context)),
      blur: 20,
      opacity: 0.15,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context),
          SizedBox(height: DesignTokens.xxl(context)),
          Obx(() => controller.isOTPSent.value
              ? _buildOTPForm(context)
              : _buildEmailForm(context)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        GlassmorphicContainer(
          width: 80,
          height: 80,
          borderRadius: BorderRadius.circular(DesignTokens.radiusXl(context)),
          child: Icon(
            Icons.auto_awesome_rounded,
            size: 40,
            color: Colors.white,
          ),
        ),
        SizedBox(height: DesignTokens.lg(context)),
        Text(
          'app_name'.tr,
          style: context.textTheme.headlineLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        SizedBox(height: DesignTokens.sm(context)),
        Text(
          'email_sign_in'.tr,
          style: context.textTheme.titleMedium?.copyWith(
            color: Colors.white.withOpacity(0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildEmailForm(BuildContext context) {
    return Column(
      children: [
        Text(
          'enter_email'.tr,
          style: context.textTheme.bodyLarge?.copyWith(
            color: Colors.white.withOpacity(0.9),
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: DesignTokens.xl(context)),
        _buildEmailField(context),
        SizedBox(height: DesignTokens.xl(context)),
        _buildSendOTPButton(context),
      ],
    );
  }

  Widget _buildEmailField(BuildContext context) {
    return Obx(() => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GlassmorphicContainer(
              padding: const EdgeInsets.all(4),
              borderRadius: BorderRadius.circular(DesignTokens.radiusLg(context)),
              child: TextField(
                controller: controller.emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'email'.tr,
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 16,
                  ),
                  prefixIcon: Icon(
                    Icons.email_rounded,
                    color: Colors.white.withOpacity(0.8),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusLg(context)),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  contentPadding: DesignTokens.lg(context).all,
                ),
                onChanged: (_) => controller.emailError.value = '',
              ),
            ),
            if (controller.emailError.value.isNotEmpty) ...[
              SizedBox(height: DesignTokens.sm(context)),
              Container(
                padding: DesignTokens.sm(context).all,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSm(context)),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      color: Colors.red.shade200,
                      size: 16,
                    ),
                    SizedBox(width: DesignTokens.sm(context)),
                    Expanded(
                      child: Text(
                        controller.emailError.value,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: Colors.red.shade200,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ));
  }

  Widget _buildSendOTPButton(BuildContext context) {
    return Obx(() => SizedBox(
          width: double.infinity,
          height: 56,
          child: AnimatedButton(
            onPressed: controller.isLoading.value ? null : controller.sendOTP,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: controller.isLoading.value
                      ? [
                          Colors.grey.withOpacity(0.5),
                          Colors.grey.withOpacity(0.3),
                        ]
                      : [
                          Colors.white.withOpacity(0.9),
                          Colors.white.withOpacity(0.7),
                        ],
                ),
                borderRadius: BorderRadius.circular(DesignTokens.radiusLg(context)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: controller.isLoading.value
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            context.colorScheme.primary,
                          ),
                        ),
                      )
                    : Text(
                        'send_otp'.tr,
                        style: context.textTheme.titleMedium?.copyWith(
                          color: context.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ),
        ));
  }

  Widget _buildOTPForm(BuildContext context) {
    return Column(
      children: [
        Text(
          'enter_otp'.tr,
          style: context.textTheme.bodyLarge?.copyWith(
            color: Colors.white.withOpacity(0.9),
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: DesignTokens.md(context)),
        Obx(() => Container(
              padding: DesignTokens.md(context).all,
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd(context)),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.timer_outlined,
                    color: Colors.orange.shade200,
                    size: 16,
                  ),
                  SizedBox(width: DesignTokens.sm(context)),
                  Text(
                    'otp_expires_in'.trParams({
                      'seconds': controller.otpExpiration.value.toString()
                    }),
                    style: context.textTheme.bodySmall?.copyWith(
                      color: Colors.orange.shade200,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )),
        SizedBox(height: DesignTokens.lg(context)),
        _buildOTPField(context),
        SizedBox(height: DesignTokens.xl(context)),
        _buildVerifyButton(context),
        SizedBox(height: DesignTokens.lg(context)),
        _buildOTPActions(context),
      ],
    );
  }

  Widget _buildOTPField(BuildContext context) {
    return Obx(() => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GlassmorphicContainer(
              padding: const EdgeInsets.all(4),
              borderRadius: BorderRadius.circular(DesignTokens.radiusLg(context)),
              child: TextField(
                controller: controller.otpController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 8,
                ),
                decoration: InputDecoration(
                  hintText: '000000',
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 8,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusLg(context)),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  contentPadding: DesignTokens.lg(context).all,
                ),
                onChanged: (_) => controller.otpError.value = '',
              ),
            ),
            if (controller.otpError.value.isNotEmpty) ...[
              SizedBox(height: DesignTokens.sm(context)),
              Container(
                padding: DesignTokens.sm(context).all,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSm(context)),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      color: Colors.red.shade200,
                      size: 16,
                    ),
                    SizedBox(width: DesignTokens.sm(context)),
                    Expanded(
                      child: Text(
                        controller.otpError.value,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: Colors.red.shade200,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ));
  }

  Widget _buildVerifyButton(BuildContext context) {
    return Obx(() => SizedBox(
          width: double.infinity,
          height: 56,
          child: AnimatedButton(
            onPressed: controller.isLoading.value ? null : controller.verifyOTP,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: controller.isLoading.value
                      ? [
                          Colors.grey.withOpacity(0.5),
                          Colors.grey.withOpacity(0.3),
                        ]
                      : [
                          Colors.white.withOpacity(0.9),
                          Colors.white.withOpacity(0.7),
                        ],
                ),
                borderRadius: BorderRadius.circular(DesignTokens.radiusLg(context)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: controller.isLoading.value
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            context.colorScheme.primary,
                          ),
                        ),
                      )
                    : Text(
                        'verify_otp'.tr,
                        style: context.textTheme.titleMedium?.copyWith(
                          color: context.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ),
        ));
  }

  Widget _buildOTPActions(BuildContext context) {
    return Column(
      children: [
        Obx(() => AnimatedButton(
              onPressed: controller.canResendOTP.value ? controller.resendOTP : null,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: DesignTokens.lg(context),
                  vertical: DesignTokens.md(context),
                ),
                decoration: BoxDecoration(
                  color: controller.canResendOTP.value
                      ? Colors.white.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd(context)),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  controller.canResendOTP.value
                      ? 'resend_otp'.tr
                      : 'resend_otp_in'.trParams({
                          'seconds': controller.resendCooldown.value.toString()
                        }),
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: controller.canResendOTP.value
                        ? Colors.white
                        : Colors.white.withOpacity(0.6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )),
        SizedBox(height: DesignTokens.md(context)),
        AnimatedButton(
          onPressed: controller.goBackToEmailInput,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: DesignTokens.lg(context),
              vertical: DesignTokens.md(context),
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd(context)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white.withOpacity(0.8),
                  size: 16,
                ),
                SizedBox(width: DesignTokens.sm(context)),
                Text(
                  'change_email'.tr,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
