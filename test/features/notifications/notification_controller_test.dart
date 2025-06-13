import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:appwrite/appwrite.dart';
import 'package:myapp/features/notifications/controllers/notification_controller.dart';
import 'package:myapp/features/notifications/services/notification_service.dart';
import 'package:myapp/features/notifications/models/notification_model.dart';

class FakeNotificationService extends NotificationService {
  FakeNotificationService()
      : super(
          databases: Databases(Client()),
          databaseId: 'db',
          collectionId: 'notifications',
        );
  List<NotificationModel> data = [];
  @override
  Future<List<NotificationModel>> fetchNotifications(String userId) async {
    return data;
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    final index = data.indexWhere((n) => n.id == notificationId);
    if (index != -1) data[index] = data[index].copyWith(isRead: true);
  }
}

void main() {
  test('loadNotifications stores data', () async {
    final service = FakeNotificationService();
    service.data = [NotificationModel(id: '1', userId: 'u', actorId: 'a', actionType: 'like', isRead: false, createdAt: DateTime.now())];
    Get.put<NotificationService>(service);
    final controller = NotificationController();
    await controller.loadNotifications('u');
    expect(controller.notifications.length, 1);
  });
}
