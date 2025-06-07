import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/splash_controller.dart';

class SplashScreen extends GetView<SplashController> {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo/Icon with animations
            Obx(() => AnimatedOpacity(
              opacity: controller.fadeOpacity.value,
              duration: const Duration(milliseconds: 800),
              child: AnimatedScale(
                scale: controller.scaleValue.value,
                duration: const Duration(milliseconds: 1200),
                curve: Curves.elasticOut,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.email,
                    size: 60,
                    color: Colors.deepPurple,
                  ),
                ),
              ),
            )),
            
            const SizedBox(height: 30),
            
            // App Name
            Obx(() => AnimatedOpacity(
              opacity: controller.fadeOpacity.value,
              duration: const Duration(milliseconds: 1000),
              child: Text(
                'app_name'.tr,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
            )),
            
            const SizedBox(height: 10),
            
            // Subtitle
            Obx(() => AnimatedOpacity(
              opacity: controller.fadeOpacity.value,
              duration: const Duration(milliseconds: 1200),
              child: Text(
                'app_subtitle'.tr,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.8),
                  letterSpacing: 1,
                ),
              ),
            )),
            
            const SizedBox(height: 50),
            
            // Loading indicator
            Obx(() => AnimatedOpacity(
              opacity: controller.fadeOpacity.value,
              duration: const Duration(milliseconds: 1400),
              child: controller.isLoading.value
                  ? const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 3,
                    )
                  : const SizedBox.shrink(),
            )),
            
            const SizedBox(height: 20),
            
            // Loading text
            Obx(() => AnimatedOpacity(
              opacity: controller.fadeOpacity.value,
              duration: const Duration(milliseconds: 1600),
              child: controller.isLoading.value
                  ? Text(
                      controller.loadingText.value.tr,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    )
                  : const SizedBox.shrink(),
            )),
          ],
        ),
      ),
    );
  }
}