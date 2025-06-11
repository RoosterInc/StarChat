// lib/pages/set_username_page.dart
// Modern username setup with real-time validation and animations

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../design_system/modern_ui_system.dart';
import 'dart:ui';

class ModernSetUsernamePage extends StatefulWidget {
  const ModernSetUsernamePage({super.key});

  @override
  State<ModernSetUsernamePage> createState() => _ModernSetUsernamePageState();
}

class _ModernSetUsernamePageState extends State<ModernSetUsernamePage>
    with TickerProviderStateMixin {
  final AuthController controller = Get.find<AuthController>();
  late AnimationController _backgroundController;
  late AnimationController _formController;
  late AnimationController _validationController;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _formSlideAnimation;
  late Animation<double> _formFadeAnimation;
  late Animation<double> _validationScaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    _formController = AnimationController(
      duration: DesignTokens.durationNormal,
      vsync: this,
    );
    _validationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_backgroundController);

    _formSlideAnimation = Tween<double>(
      begin: 30.0,
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

    _validationScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _validationController,
      curve: Curves.elasticOut,
    ));

    _backgroundController.repeat();
    _formController.forward();
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _formController.dispose();
    _validationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildAnimatedBackground(context),
          _buildContent(context),
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
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                context.colorScheme.primary.withOpacity(0.7),
                context.colorScheme.secondary.withOpacity(0.5),
                context.colorScheme.tertiary.withOpacity(0.3),
              ],
              transform: GradientRotation(_backgroundAnimation.value * 2 * 3.14159),
            ),
          ),
          child: Stack(
            children: [
              // Animated particles
              ...List.generate(6, (index) {
                final offset = (index * 60.0) + (_backgroundAnimation.value * 40);
                return Positioned(
                  top: 150 + (index * 100.0) + (offset % 200),
                  left: 20 + (index * 50.0) + (offset % 100),
                  child: _buildParticle(
                    size: 30 + (index * 10.0),
                    opacity: 0.1 - (index * 0.01),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildParticle({required double size, required double opacity}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(opacity),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
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
                  _buildHeader(context),
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

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: DesignTokens.lg(context).all,
      child: Column(
        children: [
          GlassmorphicContainer(
            width: 60,
            height: 60,
            borderRadius: BorderRadius.circular(DesignTokens.radiusLg(context)),
            child: Icon(
              Icons.person_add_rounded,
              size: 30,
              color: Colors.white,
            ),
          ),
          SizedBox(height: DesignTokens.md(context)),
          Text(
            'enter_username'.tr,
            style: context.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: DesignTokens.sm(context)),
          Text(
            'Choose a unique username to continue',
            style: context.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
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
          _buildUsernameField(context),
          SizedBox(height: DesignTokens.lg(context)),
          _buildValidationStatus(context),
          SizedBox(height: DesignTokens.xl(context)),
          _buildSubmitButton(context),
        ],
      ),
    );
  }

  Widget _buildUsernameField(BuildContext context) {
    return Obx(() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassmorphicContainer(
          padding: const EdgeInsets.all(4),
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg(context)),
          child: TextField(
            controller: controller.usernameController,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: 'username'.tr,
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 18,
              ),
              prefixIcon: Icon(
                Icons.alternate_email_rounded,
                color: Colors.white.withOpacity(0.8),
              ),
              suffixIcon: controller.usernameText.value.isNotEmpty
                  ? AnimatedButton(
                      onPressed: controller.clearUsernameInput,
                      child: Icon(
                        Icons.clear_rounded,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusLg(context)),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              contentPadding: DesignTokens.lg(context).all,
            ),
            onChanged: (value) {
              controller.onUsernameChanged(value);
              if (controller.hasCheckedUsername.value) {
                _validationController.forward();
              }
            },
          ),
        ),
        if (controller.usernameError.value.isNotEmpty) ...[
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
                    controller.usernameError.value,
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

  Widget _buildValidationStatus(BuildContext context) {
    return Obx(() {
      if (!controller.hasCheckedUsername.value && 
          controller.usernameText.value.isEmpty) {
        return const SizedBox.shrink();
      }

      return AnimatedBuilder(
        animation: _validationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _validationScaleAnimation.value,
            child: _buildValidationContent(context),
          );
        },
      );
    });
  }

  Widget _buildValidationContent(BuildContext context) {
    return Obx(() {
      if (controller.isCheckingUsername.value) {
        return _buildValidationCard(
          context,
          icon: Container(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade200),
            ),
          ),
          title: 'Checking availability...',
          subtitle: 'Please wait while we verify your username',
          color: Colors.blue,
        );
      }

      if (!controller.isUsernameValid.value && controller.usernameText.value.isNotEmpty) {
        return _buildValidationCard(
          context,
          icon: Icon(Icons.close_rounded, color: Colors.red.shade200, size: 20),
          title: 'Invalid username',
          subtitle: 'Username must be 3-15 characters with letters, numbers, and underscores only',
          color: Colors.red,
        );
      }

      if (controller.isUsernameValid.value && !controller.usernameAvailable.value) {
        return _buildValidationCard(
          context,
          icon: Icon(Icons.close_rounded, color: Colors.orange.shade200, size: 20),
          title: 'Username taken',
          subtitle: 'This username is already in use. Please try another one.',
          color: Colors.orange,
        );
      }

      if (controller.isUsernameValid.value && controller.usernameAvailable.value) {
        return _buildValidationCard(
          context,
          icon: Icon(Icons.check_rounded, color: Colors.green.shade200, size: 20),
          title: 'Username available!',
          subtitle: 'Great choice! This username is ready to use.',
          color: Colors.green,
        );
      }

      return const SizedBox.shrink();
    });
  }

  Widget _buildValidationCard(
    BuildContext context, {
    required Widget icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: DesignTokens.md(context).all,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd(context)),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          icon,
          SizedBox(width: DesignTokens.md(context)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.textTheme.titleSmall?.copyWith(
                    color: color.shade200,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: color.shade200.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    return Obx(() {
      final isEnabled = controller.isUsernameValid.value && 
                       controller.usernameAvailable.value &&
                       !controller.isLoading.value;

      return SizedBox(
        width: double.infinity,
        height: 56,
        child: AnimatedButton(
          onPressed: isEnabled ? controller.submitUsername : null,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isEnabled
                    ? [
                        Colors.white.withOpacity(0.9),
                        Colors.white.withOpacity(0.7),
                      ]
                    : [
                        Colors.grey.withOpacity(0.5),
                        Colors.grey.withOpacity(0.3),
                      ],
              ),
              borderRadius: BorderRadius.circular(DesignTokens.radiusLg(context)),
              boxShadow: isEnabled
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: controller.isLoading.value
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              context.colorScheme.primary,
                            ),
                          ),
                        ),
                        SizedBox(width: DesignTokens.sm(context)),
                        Text(
                          'Creating account...',
                          style: context.textTheme.titleMedium?.copyWith(
                            color: context.colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_rounded,
                          color: isEnabled 
                              ? context.colorScheme.primary
                              : context.colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                        SizedBox(width: DesignTokens.sm(context)),
                        Text(
                          'save'.tr,
                          style: context.textTheme.titleMedium?.copyWith(
                            color: isEnabled 
                                ? context.colorScheme.primary
                                : context.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      );
    });
  }
}
