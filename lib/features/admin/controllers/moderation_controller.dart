import 'package:get/get.dart';
import '../../profile/services/activity_service.dart';
import '../../authentication/controllers/auth_controller.dart';
import 'package:appwrite/appwrite.dart';
import '../models/report.dart';
import '../services/moderation_service.dart';

class ModerationController extends GetxController {
  final ModerationService service;
  final ActivityService activityService;

  ModerationController({required this.service, required this.activityService});

  final reports = <Report>[].obs;
  final isLoading = false.obs;
  final isModerator = false.obs;

  Future<void> loadReports() async {
    final auth = Get.find<AuthController>();
    final uid = auth.userId;
    if (uid == null) return;
    isLoading.value = true;
    try {
      final teams = Teams(auth.client);
      final memberships = await teams.listMemberships(
        teamId: 'moderators',
        queries: [Query.equal('userId', uid)],
      );
      isModerator.value = memberships.memberships.isNotEmpty;
      if (!isModerator.value) return;
      reports.value = await service.fetchPendingReports();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> reviewReport(Report report, String action) async {
    final uid = Get.find<AuthController>().userId;
    if (uid == null) return;
    await service.reviewReport(report.id, uid, action);
    await activityService.logActivity(
      uid,
      'review_report',
      itemId: report.id,
      itemType: action,
    );
    reports.removeWhere((r) => r.id == report.id);
  }
}
