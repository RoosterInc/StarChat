import 'package:get/get.dart';
import '../utils/logger.dart';
import 'auth_controller.dart';

class SplashController extends GetxController {

  final isLoading = true.obs;
  final loadingText = 'checking_session'.obs;

  @override
  void onInit() {
    super.onInit();
    final loggedOut = Get.currentRoute == '/logged-out' ||
        (Get.arguments?['loggedOut'] as bool?) == true;
    if (!loggedOut) {
      _startInitialization();
    } else {
      isLoading.value = false;
    }
  }

  Future<void> _startInitialization() async {
    try {
      final authController = Get.find<AuthController>();
      await Future.wait([
        authController.checkExistingSession(navigateOnMissing: false),
        Future.delayed(const Duration(seconds: 2)),
      ]);
    } catch (e) {
      logger.e('Splash initialization error: $e');
      Get.offAllNamed('/');
    } finally {
      isLoading.value = false;
    }
  }
}
