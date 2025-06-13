import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/auth_controller.dart';
import '../controllers/notification_controller.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  @override
  void initState() {
    super.initState();
    final userId =
        Get.isRegistered<AuthController>() ? Get.find<AuthController>().userId : null;
    if (userId != null) {
      Get.find<NotificationController>().loadNotifications(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NotificationController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: Obx(() => controller.isLoading.value
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: controller.notifications.length,
              itemBuilder: (context, index) {
                final n = controller.notifications[index];
                return ListTile(
                  leading: Icon(_iconForAction(n.actionType)),
                  title: Text('${n.actorId} ${n.actionType}d your ${n.itemType ?? 'content'}'),
                  subtitle: Text(n.createdAt.toString()),
                  trailing: n.isRead ? null : const Icon(Icons.circle, color: Colors.blue, size: 10),
                  onTap: () => controller.markAsRead(n.id),
                );
              },
            )),
    );
  }

  IconData _iconForAction(String type) {
    switch (type) {
      case 'comment':
        return Icons.comment;
      case 'like':
        return Icons.favorite;
      case 'follow':
        return Icons.person_add;
      case 'repost':
        return Icons.repeat;
      case 'mention':
        return Icons.alternate_email;
      case 'message':
        return Icons.message;
      default:
        return Icons.notifications;
    }
  }
}
