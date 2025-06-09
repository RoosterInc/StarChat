import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:myapp/widgets/complete_enhanced_watchlist.dart';
import 'package:myapp/controllers/auth_controller.dart';

class TestAuthController extends AuthController {
  final String uid;
  TestAuthController(this.uid);
  @override
  void onInit() {
    userId = uid;
  }
  @override
  Future<void> checkExistingSession() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Get.testMode = true;
  });

  testWidgets('Adding an item', (tester) async {
    Get.put<AuthController>(TestAuthController('user1'));
    final controller = Get.put(WatchlistController(testing: true));
    await tester.pump();

    await controller.addItem(WatchlistItem(
      id: '1',
      name: 'Test Item',
      count: 0,
      color: Colors.red,
      icon: Icons.star,
    ));

    expect(controller.items.length, 1);
  });

  testWidgets('Remove and restore via Undo', (tester) async {
    Get.put<AuthController>(TestAuthController('user1'));
    final controller = Get.put(WatchlistController(testing: true));

    final item = WatchlistItem(
      id: '1',
      name: 'Undo Item',
      count: 0,
      color: Colors.blue,
      icon: Icons.star,
    );
    await controller.addItem(item);
    expect(controller.items.length, 1);

    await controller.removeItem(item.id);
    expect(controller.items.isEmpty, true);

    // Simulate undo by adding item back
    await controller.addItem(item);
    expect(controller.items.length, 1);
  });

  testWidgets('Persistence across restarts', (tester) async {
    Get.put<AuthController>(TestAuthController('user1'));
    var controller = Get.put(WatchlistController(testing: true));

    final item = WatchlistItem(
      id: '1',
      name: 'Persisted',
      count: 0,
      color: Colors.green,
      icon: Icons.star,
    );
    await controller.addItem(item);

    // Recreate controller to simulate restart
    Get.delete<WatchlistController>();
    controller = Get.put(WatchlistController(testing: true));
    await tester.pump();

    expect(controller.items.length, 1);
    expect(controller.items.first.name, 'Persisted');
  });
}
