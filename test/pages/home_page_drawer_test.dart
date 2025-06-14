import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';

import 'package:myapp/pages/home_page.dart';
import 'package:myapp/features/bookmarks/screens/bookmark_list_page.dart';
import 'package:myapp/controllers/auth_controller.dart';
import 'package:myapp/controllers/user_type_controller.dart';
import 'package:myapp/features/notifications/controllers/notification_controller.dart';

class OfflineDatabases extends Databases {
  OfflineDatabases() : super(Client());

  @override
  Future<DocumentList> listDocuments({
    required String databaseId,
    required String collectionId,
    List<String>? queries,
  }) {
    return Future.error('offline');
  }

  @override
  Future<Document> createDocument({
    required String databaseId,
    required String collectionId,
    required String documentId,
    required Map<dynamic, dynamic> data,
    List<String>? permissions,
  }) {
    return Future.error('offline');
  }

  @override
  Future<void> deleteDocument({
    required String databaseId,
    required String collectionId,
    required String documentId,
  }) {
    return Future.error('offline');
  }
}

class TestAuthController extends AuthController {
  @override
  void onInit() {
    super.onInit();
    userId = 'u1';
    username.value = 'Tester';
    profilePictureUrl.value = '';
    databases = OfflineDatabases();
    storage = Storage(Client());
  }

  @override
  Future<void> checkExistingSession({bool navigateOnMissing = true}) async {}
}

class StubNotificationController extends NotificationController {
  @override
  void onInit() {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    dotenv.testLoad(fileInput: '');
    Get.testMode = true;
  });

  testWidgets('drawer bookmarks navigation', (tester) async {
    Get.put<AuthController>(TestAuthController());
    Get.put<UserTypeController>(UserTypeController());
    Get.put<NotificationController>(StubNotificationController());

    await tester.pumpWidget(
      GetMaterialApp(
        initialRoute: '/home',
        getPages: [
          GetPage(name: '/home', page: () => const HomePage()),
          GetPage(name: '/bookmarks', page: () => const BookmarkListPage()),
        ],
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ListTile, 'Bookmarks'), findsOneWidget);

    await tester.tap(find.widgetWithText(ListTile, 'Bookmarks'));
    await tester.pumpAndSettle();

    expect(Get.currentRoute, '/bookmarks');
  });
}
