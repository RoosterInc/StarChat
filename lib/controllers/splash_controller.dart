import 'package:get/get.dart';
import '../utils/logger.dart';
import 'auth_controller.dart';

class SplashController extends GetxController {
  final isLoading = true.obs;
  final loadingText = 'checking_session'.obs;

  @override
  void onInit() {
    super.onInit();
    _startInitialization();
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
}
