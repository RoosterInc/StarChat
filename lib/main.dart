import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'bindings/auth_binding.dart';
import 'pages/sign_in_page.dart';
import 'pages/home_page.dart';
import 'themes/app_theme.dart';
import 'assets/translations/app_translations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Email OTP Sign-In',
      theme: AppTheme.lightTheme,
      initialBinding: AuthBinding(),
      initialRoute: '/',
      getPages: [
        GetPage(
          name: '/',
          page: () => SignInPage(),
          binding: AuthBinding(),
        ),
        GetPage(
          name: '/home',
          page: () => HomePage(),
          binding: AuthBinding(),
        ),
      ],
      locale: Get.deviceLocale,
      fallbackLocale: Locale('en', 'US'),
      translations: AppTranslations(),
      supportedLocales: [
        Locale('en', 'US'),
        Locale('es', 'ES'),
        // Add other supported locales here
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
