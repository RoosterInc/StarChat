import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../authentication/controllers/auth_controller.dart';
import '../../../core/design_system/modern_ui_system.dart';
import '../controllers/notification_controller.dart';
import '../models/notification_model.dart';

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
      body: Obx(() {
        if (controller.isLoading.value) {
          return Padding(
            padding: EdgeInsets.all(DesignTokens.md(context)),
            child: Column(
              children: List.generate(
                3,
                (_) => Padding(
                  padding: EdgeInsets.only(bottom: DesignTokens.sm(context)),
                  child: SkeletonLoader(
                    height: DesignTokens.xl(context),
                  ),
                ),
              ),
            ),
          );
        }
        return OptimizedListView(
          itemCount: controller.notifications.length,
          padding: EdgeInsets.all(DesignTokens.md(context)),
          itemBuilder: (context, index) {
            final n = controller.notifications[index];
            return Padding(
              padding: EdgeInsets.only(bottom: DesignTokens.sm(context)),
              child: Semantics(
                label: _labelFor(n),
                button: true,
                child: ListTile(
                  leading: Icon(_iconForAction(n.actionType)),
                  title: Text(_labelFor(n)),
                  subtitle: Text(n.createdAt.toString()),
                    trailing: n.isRead
                        ? null
                        : Icon(
                            Icons.circle,
                            color: context.colorScheme.primary,
                            size: 10,
                          ),
                  onTap: () => controller.markAsRead(n.id),
                ),
              ),
            );
          },
        );
      }),
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
      case 'bookmark':
        return Icons.bookmark;
      case 'message':
        return Icons.message;
      default:
        return Icons.notifications;
    }
  }

  String _labelFor(NotificationModel n) {
    final action = n.actionType == 'bookmark'
        ? 'bookmarked'
        : '${n.actionType}d';
    return '${n.actorId} $action your ${n.itemType ?? 'content'}';
  }
}
