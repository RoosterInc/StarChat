// lib/main.dart - Updated to use modern UI system
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'bindings/auth_binding.dart';
import 'pages/sign_in_page.dart';
import 'pages/home_page.dart';
import 'pages/set_username_page.dart';
import 'pages/profile_page.dart';
import 'pages/chat_room_page.dart';
import 'pages/chat_rooms_list_page.dart';
import 'pages/settings_page.dart';
import 'pages/sliver_sample_page.dart';
import 'design_system/modern_ui_system.dart';
import 'assets/translations/app_translations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'controllers/theme_controller.dart';
import 'controllers/user_type_controller.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(const StarChatApp());
}

class StarChatApp extends StatelessWidget {
  const StarChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.put(ThemeController());
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
          themeMode:
              themeController.isDarkMode.value ? ThemeMode.dark : ThemeMode.light,
          initialBinding: AuthBinding(),
          initialRoute: '/',
          defaultTransition: Transition.cupertino,
          transitionDuration: DesignTokens.durationNormal,
          getPages: [
            GetPage(
              name: '/',
              page: () => const SignInPage(),
              binding: AuthBinding(),
              transition: Transition.fadeIn,
              transitionDuration: DesignTokens.durationSlow,
            ),
            GetPage(
              name: '/set_username',
              page: () => const SetUsernamePage(),
              binding: AuthBinding(),
              transition: Transition.rightToLeft,
              transitionDuration: DesignTokens.durationNormal,
            ),
            GetPage(
              name: '/home',
              page: () => const HomePage(),
              binding: AuthBinding(),
              transition: Transition.fadeIn,
              transitionDuration: DesignTokens.durationSlow,
            ),
            GetPage(
              name: '/profile',
              page: () => const ProfilePage(),
              binding: AuthBinding(),
              transition: Transition.rightToLeft,
              transitionDuration: DesignTokens.durationNormal,
            ),
            GetPage(
              name: '/settings',
              page: () => const SettingsPage(),
              binding: AuthBinding(),
              transition: Transition.rightToLeft,
              transitionDuration: DesignTokens.durationNormal,
            ),
            GetPage(
              name: '/sliver',
              page: () => const SliverSamplePage(),
              binding: AuthBinding(),
              transition: Transition.rightToLeft,
              transitionDuration: DesignTokens.durationNormal,
            ),
            GetPage(
              name: '/chat-room/:roomId',
              page: () => const ChatRoomPage(),
              binding: AuthBinding(),
              transition: Transition.rightToLeft,
              transitionDuration: DesignTokens.durationNormal,
            ),
            GetPage(
              name: '/chat-rooms-list',
              page: () => const ChatRoomsListPage(),
              binding: AuthBinding(),
              transition: Transition.rightToLeft,
              transitionDuration: DesignTokens.durationNormal,
            ),
          ],
          locale: Get.deviceLocale,
          fallbackLocale: const Locale('en', 'US'),
          translations: AppTranslations(),
          supportedLocales: const [
            Locale('en', 'US'),
            Locale('es', 'ES'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          unknownRoute: GetPage(
            name: '/notfound',
            page: () => Scaffold(
              body: Center(
                child: GlassmorphicCard(
                  padding: DesignTokens.xl(context).all,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 64,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      SizedBox(height: DesignTokens.lg(context)),
                      Text(
                        '404 - Page Not Found',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      SizedBox(height: DesignTokens.md(context)),
                      AnimatedButton(
                        onPressed: () => Get.offAllNamed('/'),
                        child: Container(
                          padding: DesignTokens.md(context).all,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).colorScheme.primary,
                                Theme.of(context).colorScheme.secondary,
                              ],
                            ),
                            borderRadius:
                                BorderRadius.circular(DesignTokens.radiusLg(context)),
                          ),
                          child: Text(
                            'Go Home',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ));
  }
}
