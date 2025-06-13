import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'bindings/auth_binding.dart';
import 'package:path_provider/path_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'features/social_feed/services/feed_service.dart';
import 'package:appwrite/appwrite.dart';
import 'controllers/auth_controller.dart';
import 'pages/sign_in_page.dart';
import 'pages/home_page.dart';
import 'pages/set_username_page.dart';
import 'pages/profile_page.dart';
import 'pages/settings_page.dart';
import 'pages/sliver_sample_page.dart';
import 'pages/chat_room_page.dart';
import 'pages/chat_rooms_list_page.dart';
import 'features/social_feed/screens/compose_post_page.dart';
import 'features/search/screens/search_page.dart';
import 'features/notifications/screens/notification_page.dart';
import 'features/bookmarks/screens/bookmark_list_page.dart';
import 'features/profile/screens/profile_page.dart';
import 'features/reports/screens/report_post_page.dart';
import 'features/reports/screens/report_user_page.dart';
import 'features/admin/screens/moderation_dashboard.dart';
import 'pages/empty_page.dart';
import 'pages/splash_screen.dart';
import 'bindings/splash_binding.dart';
import 'bindings/feed_binding.dart';
import 'bindings/search_binding.dart';
import 'bindings/notification_binding.dart';
import 'bindings/profile_binding.dart';
import 'bindings/report_binding.dart';
import 'bindings/moderation_binding.dart';
import 'design_system/modern_ui_system.dart';
import 'assets/translations/app_translations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'controllers/theme_controller.dart'; // Import the ThemeController
import 'controllers/user_type_controller.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(dir.path);
  await Hive.openBox('posts');
  await Hive.openBox('comments');
  await Hive.openBox('action_queue');
  await Hive.openBox('post_queue');
  await Hive.openBox('profiles');
  await Hive.openBox('notifications');
  await Hive.openBox('follows');
  await Hive.openBox('bookmarks');
  await Hive.openBox('blocks');
  await Hive.openBox('preferences');
  await Hive.openBox('activities');
  await dotenv.load(fileName: '.env');

  AuthBinding().dependencies();
  final auth = Get.find<AuthController>();
  final feedService = FeedService(
    databases: auth.databases,
    storage: auth.storage,
    functions: Functions(auth.client),
    databaseId: dotenv.env['APPWRITE_DATABASE_ID'] ?? 'StarChat_DB',
    postsCollectionId:
        dotenv.env['FEED_POSTS_COLLECTION_ID'] ?? 'feed_posts',
    commentsCollectionId:
        dotenv.env['POST_COMMENTS_COLLECTION_ID'] ?? 'post_comments',
    likesCollectionId:
        dotenv.env['POST_LIKES_COLLECTION_ID'] ?? 'post_likes',
    repostsCollectionId:
        dotenv.env['POST_REPOSTS_COLLECTION_ID'] ?? 'post_reposts',
    bookmarksCollectionId:
        dotenv.env['BOOKMARKS_COLLECTION_ID'] ?? 'bookmarks',
    connectivity: Connectivity(),
    linkMetadataFunctionId:
        dotenv.env['FETCH_LINK_METADATA_FUNCTION_ID'] ?? 'fetch_link_metadata',
  );
  Get.put(feedService, permanent: true);
  if (await Connectivity().checkConnectivity() != ConnectivityResult.none) {
    await feedService.syncQueuedActions();
  }
  Connectivity().onConnectivityChanged.listen((result) async {
    if (result != ConnectivityResult.none) {
      await feedService.syncQueuedActions();
    }
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize the ThemeController
    final themeController = Get.put(ThemeController());
    // Make UserTypeController globally available
    Get.put(UserTypeController(), permanent: true);

    return Obx(() => GetMaterialApp(
          title: 'StarChat',
          theme: MD3ThemeSystem.createTheme(
            seedColor: Colors.deepPurple,
            brightness: Brightness.light,
          ),
          darkTheme: MD3ThemeSystem.createTheme(
            seedColor: Colors.deepPurple,
            brightness: Brightness.dark,
          ),
          themeMode: themeController.isDarkMode.value
              ? ThemeMode.dark
              : ThemeMode.light, // Reactive theme
          initialBinding: AuthBinding(),
          initialRoute: '/splash',
          defaultTransition: Transition.cupertino,
          transitionDuration: const Duration(milliseconds: 300),
          getPages: [
            GetPage(
              name: '/splash',
              page: () => const SplashScreen(),
              binding: SplashBinding(),
              transition: Transition.fadeIn,
              transitionDuration: const Duration(milliseconds: 400),
            ),
            GetPage(
              name: '/',
              page: () => const SignInPage(),
              binding: AuthBinding(),
              transition: Transition.fadeIn,
              transitionDuration: const Duration(milliseconds: 400),
            ),
            GetPage(
              name: '/logged-out',
              page: () => const SplashScreen(),
              binding: SplashBinding(),
              transition: Transition.fadeIn,
              transitionDuration: const Duration(milliseconds: 400),
            ),
            GetPage(
              name: '/set_username',
              page: () => const SetUsernamePage(),
              binding: AuthBinding(),
              transition: Transition.rightToLeft,
            ),
            GetPage(
              name: '/home',
              page: () => const HomePage(),
              binding: AuthBinding(),
              transition: Transition.fadeIn,
              transitionDuration: const Duration(milliseconds: 500),
            ),
            GetPage(
              name: '/profile',
              page: () => const ProfilePage(),
              binding: AuthBinding(),
              transition: Transition.rightToLeft,
            ),
            GetPage(
              name: '/settings',
              page: () => const SettingsPage(),
              binding: AuthBinding(),
              transition: Transition.rightToLeft,
            ),
            GetPage(
              name: '/sliver',
              page: () => const SliverSamplePage(),
              binding: AuthBinding(),
              transition: Transition.rightToLeft,
            ),
            GetPage(
              name: '/chat-room/:roomId',
              page: () => const ChatRoomPage(),
              bindings: [AuthBinding(), FeedBinding()],
              transition: Transition.rightToLeft,
            ),
            GetPage(
              name: '/search',
              page: () => const SearchPage(),
              binding: SearchBinding(),
            ),
            GetPage(
              name: '/notifications',
              page: () => const NotificationPage(),
              binding: NotificationBinding(),
            ),
            GetPage(
              name: '/bookmarks',
              page: () => const BookmarkListPage(),
              bindings: [AuthBinding(), FeedBinding()],
            ),
            GetPage(
              name: '/user-profile/:userId',
              page: () => UserProfilePage(userId: Get.parameters['userId']!),
              binding: ProfileBinding(),
            ),
            GetPage(
              name: '/compose-post/:roomId',
              page: () => ComposePostPage(roomId: Get.parameters['roomId']!),
              bindings: [AuthBinding(), FeedBinding()],
            ),
            GetPage(
              name: '/post/:postId',
              page: () => const EmptyPage(),
              binding: AuthBinding(),
            ),
            GetPage(
              name: '/comments/:postId',
              page: () => const EmptyPage(),
              binding: AuthBinding(),
            ),
            GetPage(
              name: '/report-post/:postId',
              page: () => ReportPostPage(postId: Get.parameters['postId']!),
              binding: ReportBinding(),
            ),
            GetPage(
              name: '/report-user/:userId',
              page: () => ReportUserPage(userId: Get.parameters['userId']!),
              binding: ReportBinding(),
            ),
            GetPage(
              name: '/moderation',
              page: () => const ModerationDashboard(),
              binding: ModerationBinding(),
            ),
            GetPage(
              name: '/chat-rooms-list',
              page: () => const ChatRoomsListPage(),
              binding: AuthBinding(),
              transition: Transition.rightToLeft,
            ),
          ],
          locale: Get.deviceLocale,
          fallbackLocale: const Locale('en', 'US'),
          translations: AppTranslations(),
          supportedLocales: const [
            Locale('en', 'US'),
            Locale('es', 'ES'),
            // Add other supported locales here
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          unknownRoute: GetPage(
            name: '/notfound',
            page: () => Scaffold(
              appBar: AppBar(title: const Text('Page Not Found')),
              body: const Center(child: Text('404 - Page Not Found')),
            ),
          ),
        ));
  }
}
