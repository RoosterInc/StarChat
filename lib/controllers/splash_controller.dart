import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'auth_controller.dart';

class SplashController extends GetxController with GetSingleTickerProviderStateMixin {
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
      // Get AuthController instance
      final authController = Get.find<AuthController>();
      
      // Add minimum splash duration for better UX
      await Future.wait([
        authController.checkExistingSession(),
        Future.delayed(const Duration(seconds: 2)), // Minimum splash time
      ]);
      
    } catch (e) {
      // If any error occurs, navigate to sign-in
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
