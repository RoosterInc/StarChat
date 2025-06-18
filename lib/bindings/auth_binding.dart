import 'package:get/get.dart';
import '../features/authentication/controllers/auth_controller.dart';
import '../features/chat/controllers/chat_controller.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    // Keep a single instance of AuthController alive for the
    // entire application lifecycle to preserve state such as
    // the `justLoggedOut` flag during navigation.
    Get.put<AuthController>(AuthController(), permanent: true);
    if (!Get.isRegistered<ChatController>()) {
      Get.put(ChatController(), permanent: true);
    }
  }
}
