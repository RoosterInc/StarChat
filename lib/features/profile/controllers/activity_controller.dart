import 'package:get/get.dart';
import '../models/activity_log.dart';
import '../services/activity_service.dart';

class ActivityController extends GetxController {
  final ActivityService service;

  ActivityController({required this.service});

  final logs = <ActivityLog>[].obs;
  final isLoading = false.obs;

  Future<void> loadActivities(String userId) async {
    isLoading.value = true;
    try {
      final data = await service.fetchActivities(userId);
      logs.assignAll(data.map(ActivityLog.fromJson));
    } finally {
      isLoading.value = false;
    }
  }
}
