import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:appwrite/appwrite.dart';

import 'package:myapp/features/reports/screens/report_user_page.dart';
import 'package:myapp/features/reports/services/report_service.dart';
import 'package:myapp/features/reports/models/report_type.dart';
import 'package:myapp/controllers/auth_controller.dart';

class FakeReportService extends ReportService {
  Map<String, dynamic>? lastCall;
  bool shouldThrow = false;
  FakeReportService()
      : super(
          databases: Databases(Client()),
          databaseId: 'db',
          collectionId: 'reports',
        );

  @override
  Future<void> reportUser(
    String reporterId,
    String reportedUserId,
    ReportType reportType,
    String description,
  ) async {
    if (shouldThrow) throw Exception('fail');
    lastCall = {
      'reporterId': reporterId,
      'reportedUserId': reportedUserId,
      'type': reportType,
      'description': description,
    };
  }
}

class TestAuthController extends AuthController {
  TestAuthController(String? id) {
    userId = id;
  }

  @override
  Future<void> checkExistingSession({bool navigateOnMissing = true}) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.testMode = true;
  });

  testWidgets('self reporting shows snackbar and aborts', (tester) async {
    final service = FakeReportService();
    Get.put<ReportService>(service);
    Get.put<AuthController>(TestAuthController('u1'));

    await tester.pumpWidget(
      GetMaterialApp(
        home: const ReportUserPage(userId: 'u1'),
      ),
    );

    await tester.tap(find.text('Submit'));
    await tester.pump();

    expect(service.lastCall, isNull);
    expect(find.text('You cannot report yourself'), findsOneWidget);
  });

  testWidgets('submit calls reportUser when logged in', (tester) async {
    final service = FakeReportService();
    Get.put<ReportService>(service);
    Get.put<AuthController>(TestAuthController('u1'));

    await tester.pumpWidget(
      GetMaterialApp(
        home: const ReportUserPage(userId: 'u2'),
      ),
    );

    await tester.enterText(find.byType(TextField), 'desc');
    await tester.tap(find.text('Submit'));
    await tester.pump();

    expect(service.lastCall?['reporterId'], 'u1');
    expect(service.lastCall?['reportedUserId'], 'u2');
    expect(service.lastCall?['type'], ReportType.spam);
    expect(service.lastCall?['description'], 'desc');
  });

  testWidgets('unauthenticated submission shows error', (tester) async {
    final service = FakeReportService();
    Get.put<ReportService>(service);
    Get.put<AuthController>(TestAuthController(null));

    await tester.pumpWidget(
      GetMaterialApp(
        home: const ReportUserPage(userId: 'u2'),
      ),
    );

    await tester.tap(find.text('Submit'));
    await tester.pump();

    expect(service.lastCall, isNull);
    expect(find.text('Login required'), findsOneWidget);
  });

  testWidgets('error snackbar shown on failure', (tester) async {
    final service = FakeReportService()..shouldThrow = true;
    Get.put<ReportService>(service);
    Get.put<AuthController>(TestAuthController('u1'));

    await tester.pumpWidget(
      GetMaterialApp(
        home: const ReportUserPage(userId: 'u2'),
      ),
    );

    await tester.tap(find.text('Submit'));
    await tester.pump();

    expect(find.text('Failed to submit report'), findsOneWidget);
  });
}
