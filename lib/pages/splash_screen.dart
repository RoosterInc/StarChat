import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/splash_controller.dart';
import '../design_system/modern_ui_system.dart';

class SplashScreen extends GetView<SplashController> {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
                'assets/images/planets/Splash Screen background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(),
              Text(
                'app_name'.tr,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: context.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: DesignTokens.lg(context)),
              Obx(() {
                if (controller.isLoading.value) {
                  return CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      context.colorScheme.onPrimary,
                    ),
                  );
                }
                return Padding(
                  padding: DesignTokens.lg(context).horizontal,
                  child: AnimatedButton(
                    onPressed: () => Get.offAllNamed('/'),
                    style: FilledButton.styleFrom(
                      minimumSize: Size.fromHeight(
                        ResponsiveUtils.fluidSize(context, min: 50, max: 70),
                      ),
                    ),
                    child: Text(
                      'lets_go'.tr,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }),
              SizedBox(height: DesignTokens.xl(context)),
            ],
          ),
        ),
      ),
    );
  }
}
