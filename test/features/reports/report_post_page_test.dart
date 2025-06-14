import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:appwrite/appwrite.dart';

import 'package:myapp/features/reports/screens/report_post_page.dart';
import 'package:myapp/features/reports/services/report_service.dart';
import 'package:myapp/features/reports/models/report_type.dart';
import 'package:myapp/controllers/auth_controller.dart';

class RecordingReportService extends ReportService {
  Map<String, dynamic>? lastCall;
  bool shouldThrow = false;
  RecordingReportService()
      : super(databases: Databases(Client()), databaseId: 'db', collectionId: 'rep');

  @override
  Future<void> reportPost(
      String reporterId, String postId, ReportType type, String desc) async {
    if (shouldThrow) throw Exception('fail');
    lastCall = {
      'reporterId': reporterId,
      'postId': postId,
      'type': type,
      'desc': desc,
    };
  }
}

class FakeAuthController extends AuthController {
  FakeAuthController({String? id}) {
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

  testWidgets('submit calls reportPost with values', (tester) async {
    final service = RecordingReportService();
    Get.put<ReportService>(service);
    Get.put<AuthController>(FakeAuthController(id: 'u1'));

    await tester.pumpWidget(const GetMaterialApp(home: ReportPostPage(postId: 'p1')));
    await tester.enterText(find.byType(TextField), 'bad');
    await tester.tap(find.text('Submit'));
    await tester.pump();

    expect(service.lastCall?['reporterId'], 'u1');
    expect(service.lastCall?['postId'], 'p1');
    expect(service.lastCall?['type'], ReportType.spam);
    expect(service.lastCall?['desc'], 'bad');
  });

  testWidgets('shows login required when unauthenticated', (tester) async {
    final service = RecordingReportService();
    Get.put<ReportService>(service);
    Get.put<AuthController>(FakeAuthController());

    await tester.pumpWidget(const GetMaterialApp(home: ReportPostPage(postId: 'p1')));
    await tester.tap(find.text('Submit'));
    await tester.pump();

    expect(find.text('Login required'), findsOneWidget);
    expect(service.lastCall, isNull);
  });

  testWidgets('error snackbar shown on failure', (tester) async {
    final service = RecordingReportService()..shouldThrow = true;
    Get.put<ReportService>(service);
    Get.put<AuthController>(FakeAuthController(id: 'u1'));

    await tester.pumpWidget(const GetMaterialApp(home: ReportPostPage(postId: 'p1')));
    await tester.tap(find.text('Submit'));
    await tester.pump();

    expect(find.text('Failed to submit report'), findsOneWidget);
  });
}
