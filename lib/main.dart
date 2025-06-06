import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Import controllers
import 'controllers/theme_controller.dart';

// Import pages
import 'pages/splash_screen.dart';
import 'pages/sign_in_page.dart';
import 'pages/home_page.dart';

// Import bindings
import 'bindings/auth_binding.dart';
import 'bindings/splash_binding.dart';

// Import themes and translations
import 'themes/app_theme.dart';
import 'assets/translations/app_translations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // Debug: Print loaded environment variables
  print('Loaded environment variables: ${dotenv.env}');

  runZonedGuarded(() {
    runApp(const MyApp());
  }, (error, stackTrace) {
    print('Uncaught error: $error');
    print('Stack trace: $stackTrace');
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize the ThemeController
    final themeController = Get.put(ThemeController());

    return Obx(() => GetMaterialApp(
          title: 'Email OTP Sign-In',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeController.isDarkMode.value
              ? ThemeMode.dark
              : ThemeMode.light,
          initialRoute: '/splash',
          getPages: [
            GetPage(
              name: '/splash',
              page: () => const SplashScreen(),
              binding: SplashBinding(),
            ),
            GetPage(
              name: '/',
              page: () => const SignInPage(),
              binding: AuthBinding(),
            ),
            GetPage(
              name: '/home',
              page: () => const HomePage(),
              binding: AuthBinding(),
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
              appBar: AppBar(title: const Text('Page Not Found')),
              body: const Center(child: Text('404 - Page Not Found')),
            ),
          ),
        ));
  }
}