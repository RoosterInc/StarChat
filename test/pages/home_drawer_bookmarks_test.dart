import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:myapp/pages/home_page.dart';
import 'package:myapp/features/bookmarks/screens/bookmark_list_page.dart';
import 'package:myapp/controllers/auth_controller.dart';
import 'package:myapp/controllers/user_type_controller.dart';
import 'package:myapp/features/notifications/controllers/notification_controller.dart';
import 'package:myapp/controllers/enhanced_planet_house_controller.dart';
import 'package:myapp/widgets/complete_enhanced_watchlist.dart';

class TestAuthController extends AuthController {
  TestAuthController(String id) {
    userId = id;
  }

  @override
  Future<void> checkExistingSession({bool navigateOnMissing = true}) async {}
}

class TestNotificationController extends NotificationController {
  @override
  void onInit() {}
}

class TestPlanetHouseController extends EnhancedPlanetHouseController {
  @override
  Future<void> initialize() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    dotenv.testLoad(fileInput: '');
    Get.testMode = true;
  });

  testWidgets('drawer bookmarks navigation', (tester) async {
    Get.put<AuthController>(TestAuthController('user1'));
    Get.put<UserTypeController>(UserTypeController());
    Get.put<NotificationController>(TestNotificationController());
    Get.put<EnhancedPlanetHouseController>(TestPlanetHouseController());
    Get.lazyPut<WatchlistController>(() => WatchlistController(testing: true));

    await tester.pumpWidget(
      GetMaterialApp(
        home: const HomePage(),
        getPages: [
          GetPage(name: '/bookmarks', page: () => const BookmarkListPage()),
        ],
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bookmarks'));
    await tester.pumpAndSettle();

    expect(Get.currentRoute, '/bookmarks');
    expect(find.byType(BookmarkListPage), findsOneWidget);
  });
}
