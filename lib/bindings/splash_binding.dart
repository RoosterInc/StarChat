import 'package:get/get.dart';
import '../features/splash/controllers/splash_controller.dart';
import '../features/authentication/controllers/auth_controller.dart';

class SplashBinding extends Bindings {
  @override
  void dependencies() {
    // Ensure a permanent AuthController is available before
    // running splash logic.
    Get.put<AuthController>(AuthController(), permanent: true);

    // Initialize SplashController lazily
    Get.lazyPut<SplashController>(() => SplashController());
  }
}