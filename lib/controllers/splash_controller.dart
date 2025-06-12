import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../utils/logger.dart';
import 'auth_controller.dart';

class SplashController extends GetxController
    with GetSingleTickerProviderStateMixin {
  late AnimationController animationController;
  final fadeOpacity = 0.0.obs;
  final scaleValue = 0.5.obs;

  final isLoading = true.obs;
  final loadingText = 'checking_session'.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeAnimations();
    _startInitialization();
  }

  void _initializeAnimations() {
    animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // Start animations
    animationController.forward();
    _startFadeAnimation();
    _startScaleAnimation();
  }

  void _startFadeAnimation() {
    fadeOpacity.value = 1.0;
  }

  void _startScaleAnimation() {
    Future.delayed(const Duration(milliseconds: 300), () {
      scaleValue.value = 1.0;
    });
  }

  Future<void> _startInitialization() async {
    try {
      final authController = Get.find<AuthController>();

      await Future.wait([
        authController.checkExistingSession(),
        Future.delayed(const Duration(seconds: 2)),
      ]);

      await Future.delayed(const Duration(milliseconds: 500));

      if (Get.currentRoute == '/splash') {
        logger.w('Splash: AuthController did not navigate, using fallback');
        Get.offAllNamed('/');
      }
    } catch (e) {
      logger.e('Splash initialization error: $e');
      Get.offAllNamed('/');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    animationController.dispose();
    super.onClose();
  }
}
