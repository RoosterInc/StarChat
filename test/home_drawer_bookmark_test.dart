import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:appwrite/appwrite.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:myapp/pages/home_page.dart';
import 'package:myapp/controllers/auth_controller.dart';
import 'package:myapp/features/bookmarks/screens/bookmark_list_page.dart';
import 'package:myapp/features/bookmarks/controllers/bookmark_controller.dart';
import 'package:myapp/features/social_feed/services/feed_service.dart';
import 'package:myapp/features/notifications/services/notification_service.dart';
import 'package:myapp/features/notifications/controllers/notification_controller.dart';

class FakeAuthController extends AuthController {
  FakeAuthController() {
    userId = 'u1';
    account = Account(client);
    databases = Databases(client);
    storage = Storage(client);
  }

  @override
  void onInit() {}

  @override
  Future<void> checkExistingSession({bool navigateOnMissing = true}) async {}
}

class FakeFeedService extends FeedService {
  FakeFeedService()
      : super(
          databases: Databases(Client()),
          storage: Storage(Client()),
          functions: Functions(Client()),
          databaseId: 'db',
          postsCollectionId: 'posts',
          commentsCollectionId: 'comments',
          likesCollectionId: 'likes',
          repostsCollectionId: 'reposts',
          bookmarksCollectionId: 'bookmarks',
          connectivity: Connectivity(),
          linkMetadataFunctionId: 'link',
          validateReactionFunctionId: 'validate',
        );

  @override
  Future<List<BookmarkedPost>> listBookmarks(String userId) async => [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    dotenv.testLoad(fileInput: '');
    final dir = await Directory.systemTemp.createTemp();
    Hive.init(dir.path);
    await Hive.openBox('notifications');
    await Hive.openBox('notification_queue');
    Get.testMode = true;
    Get.put<AuthController>(FakeAuthController());
    Get.put<NotificationService>(NotificationService(
      databases: Databases(Client()),
      databaseId: 'db',
      collectionId: 'notifications',
      connectivity: Connectivity(),
    ));
    Get.put<NotificationController>(NotificationController());
    Get.put<BookmarkController>(BookmarkController(service: FakeFeedService()));
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    Get.reset();
  });

  testWidgets('bookmark tile appears and navigates', (tester) async {
    await tester.pumpWidget(GetMaterialApp(
      initialRoute: '/',
      getPages: [
        GetPage(name: '/', page: () => const HomePage()),
        GetPage(name: '/bookmarks', page: () => const BookmarkListPage()),
      ],
    ));

    // open drawer
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();

    expect(find.text('Bookmarks'), findsOneWidget);

    await tester.tap(find.widgetWithText(ListTile, 'Bookmarks'));
    await tester.pumpAndSettle();

    expect(find.byType(BookmarkListPage), findsOneWidget);
  });
}
