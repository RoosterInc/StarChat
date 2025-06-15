import 'package:get/get.dart';
import 'package:appwrite/appwrite.dart';
import 'package:flutter_app_badge/flutter_app_badge.dart';

import '../../authentication/controllers/auth_controller.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationController extends GetxController {
  final notifications = <NotificationModel>[].obs;
  final unreadCount = 0.obs;
  final isLoading = false.obs;

  Realtime? _realtime;
  RealtimeSubscription? _subscription;

  @override
  void onInit() {
    super.onInit();
    final auth = Get.isRegistered<AuthController>() ? Get.find<AuthController>() : null;
    final service = Get.find<NotificationService>();
    final userId = auth?.userId;
    if (auth != null && userId != null) {
      _realtime = Realtime(auth.client);
      _subscription = _realtime!.subscribe([
        'databases.${service.databaseId}.collections.${service.collectionId}.documents'
      ]);
      _subscription!.stream.listen((event) {
        final payload = event.payload;
        if (payload['user_id'] == userId) {
          final notification = NotificationModel.fromJson(payload);
          notifications.insert(0, notification);

          final box = service.notificationBox;
          final cached = box.get('notifications_$userId', defaultValue: []) as List;
          cached.insert(0, notification.toJson());
          box.put('notifications_$userId', cached);

          if (!notification.isRead) {
            final count = box.get('unread_count_$userId', defaultValue: 0) as int;
            final newCount = count + 1;
            box.put('unread_count_$userId', newCount);
            unreadCount.value = newCount;
            FlutterAppBadge.count(newCount);
          }
        }
      });
    }
  }

  @override
  void onClose() {
    _subscription?.close();
    super.onClose();
  }

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
