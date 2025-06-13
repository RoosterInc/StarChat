import 'package:get/get.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationController extends GetxController {
  var notifications = <NotificationModel>[].obs;
  var unreadCount = 0.obs;
  var isLoading = false.obs;

  Future<void> loadNotifications(String userId) async {
    isLoading.value = true;
    try {
      notifications.value = await Get.find<NotificationService>().fetchNotifications(userId);
      unreadCount.value = notifications.where((n) => !n.isRead).length;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> markAsRead(String notificationId) async {
    await Get.find<NotificationService>().markAsRead(notificationId);
    final index = notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      notifications[index] = notifications[index].copyWith(isRead: true);
      unreadCount.value = notifications.where((n) => !n.isRead).length;
    }
  }
}
