import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:appwrite/appwrite.dart';

import 'package:myapp/features/reports/screens/report_user_page.dart';
import 'package:myapp/features/reports/services/report_service.dart';
import 'package:myapp/features/reports/models/report_type.dart';
import 'package:myapp/controllers/auth_controller.dart';

class FakeReportService extends ReportService {
  bool called = false;
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
    called = true;
  }
}

class TestAuthController extends AuthController {
  TestAuthController(String id) {
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

    expect(service.called, isFalse);
    expect(find.text('You cannot report yourself'), findsOneWidget);
  });
}
