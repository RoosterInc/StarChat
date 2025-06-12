import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:myapp/controllers/chat_controller.dart';
import 'package:myapp/controllers/auth_controller.dart';

class FakeDatabases {
  Future<dynamic> listDocuments({
    String? databaseId,
    String? collectionId,
    List<dynamic>? queries,
  }) async {
    throw Exception('db unavailable');
  }
}

class TestAuthController extends AuthController {
  @override
  void onInit() {
    super.onInit();
    databases = FakeDatabases() as dynamic;
  }

  @override
  Future<void> checkExistingSession({bool navigateOnMissing = true}) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Get.testMode = true;
  });

  test('falls back to mock rooms when load fails', () async {
    Get.put<AuthController>(TestAuthController());
    final controller = Get.put(ChatController());
    await Future.delayed(const Duration(milliseconds: 100));
    expect(controller.rashiRooms.length, 12);
  }, skip: true);

  test('join and leave rooms', () async {
    final controller = Get.find<ChatController>();
    await controller.joinRoom('1');
    expect(controller.joinedRooms.length, 1);
    await controller.leaveRoom('1');
    expect(controller.joinedRooms.isEmpty, true);
    Get.delete<ChatController>();
    Get.delete<AuthController>();
  }, skip: true);
}
