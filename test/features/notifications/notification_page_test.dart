import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:appwrite/appwrite.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:myapp/features/notifications/controllers/notification_controller.dart';
import 'package:myapp/features/notifications/screens/notification_page.dart';
import 'package:myapp/features/notifications/services/notification_service.dart';
import 'package:myapp/features/notifications/models/notification_model.dart';
import 'package:myapp/design_system/modern_ui_system.dart' show MD3ThemeSystem, SkeletonLoader;
import 'package:myapp/controllers/auth_controller.dart';

void main() {
  testWidgets('renders notification page', (tester) async {
    Get.put(NotificationController());
    await tester.pumpWidget(const GetMaterialApp(home: NotificationPage()));
    expect(find.text('Notifications'), findsOneWidget);
  });

  testWidgets('shows skeleton loader while loading', (tester) async {
    class TestAuthController extends AuthController {
      TestAuthController() {
        userId = 'u1';
      }

      @override
      Future<void> checkExistingSession({bool navigateOnMissing = true}) async {}
    }

    class DelayedNotificationService extends NotificationService {
      DelayedNotificationService()
          : super(
              databases: Databases(Client()),
              databaseId: 'db',
              collectionId: 'col',
              connectivity: Connectivity(),
            );

      @override
      Future<List<NotificationModel>> fetchNotifications(String userId) {
        return Future.delayed(const Duration(milliseconds: 100), () => []);
      }
    }

    Get.put<AuthController>(TestAuthController());
    Get.put<NotificationService>(DelayedNotificationService());
    final controller = NotificationController();
    Get.put<NotificationController>(controller);

    await tester.pumpWidget(
      GetMaterialApp(
        theme: MD3ThemeSystem.createTheme(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        home: const NotificationPage(),
      ),
    );

    await tester.pump();
    expect(find.byType(SkeletonLoader), findsWidgets);
  });
}
