import 'package:get/get.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../controllers/auth_controller.dart';
import '../features/reports/services/report_service.dart';

class ReportBinding extends Bindings {
  @override
  void dependencies() {
    final auth = Get.find<AuthController>();
    Get.lazyPut<ReportService>(() => ReportService(
          databases: auth.databases,
          databaseId: dotenv.env['APPWRITE_DATABASE_ID'] ?? 'StarChat_DB',
          collectionId: 'user_reports',
        ));
  }
}
