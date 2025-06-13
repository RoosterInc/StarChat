import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:myapp/features/notifications/controllers/notification_controller.dart';
import 'package:myapp/features/notifications/screens/notification_page.dart';

void main() {
  testWidgets('renders notification page', (tester) async {
    Get.put(NotificationController());
    await tester.pumpWidget(const GetMaterialApp(home: NotificationPage()));
    expect(find.text('Notifications'), findsOneWidget);
  });
}
