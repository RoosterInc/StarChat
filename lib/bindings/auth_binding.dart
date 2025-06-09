import 'package:get/get.dart';
import '../controllers/auth_controller.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    // Keep a single instance of AuthController alive for the
    // entire application lifecycle to preserve state such as
    // the `justLoggedOut` flag during navigation.
    Get.put<AuthController>(AuthController(), permanent: true);
  }
}
