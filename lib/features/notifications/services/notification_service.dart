import 'package:appwrite/appwrite.dart';
import 'package:flutter_app_badge/flutter_app_badge.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/notification_model.dart';
import '../../authentication/controllers/auth_controller.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class NotificationService {
  final Databases databases;
  final String databaseId;
  final String collectionId;
  final Connectivity connectivity;
  final Box notificationBox = Hive.box('notifications');
  final Box queueBox = Hive.box('notification_queue');

  NotificationService({
    required this.databases,
    required this.databaseId,
    required this.collectionId,
    required this.connectivity,
  }) {
    connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (results.any((r) => r != ConnectivityResult.none)) {
        syncQueuedNotifications();
      }
    });
  }

  Future<void> createNotification(
    String userId,
    String actorId,
    String actionType, {
    String? itemId,
    String? itemType,
  }) async {
    try {
      final doc = await databases.createDocument(
        databaseId: databaseId,
        collectionId: collectionId,
        documentId: ID.unique(),
        data: {
          'user_id': userId,
          'actor_id': actorId,
          'action_type': actionType,
          'item_id': itemId,
          'item_type': itemType,
          'is_read': false,
          'created_at': DateTime.now().toIso8601String(),
        },
      );
      final cached =
          notificationBox.get('notifications_$userId', defaultValue: []) as List;
      cached.insert(0, doc.data);
      await notificationBox.put('notifications_$userId', cached);
      await _updateCount(userId, cached);
    } catch (_) {
      await queueBox.add({
        'user_id': userId,
        'actor_id': actorId,
        'action_type': actionType,
        'item_id': itemId,
        'item_type': itemType,
        '_cachedAt': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<List<NotificationModel>> fetchNotifications(String userId) async {
    try {
      final res = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: collectionId,
        queries: [Query.equal('user_id', userId), Query.orderDesc('created_at'), Query.limit(50)],
      );
      final notifications = res.documents.map((e) => NotificationModel.fromJson(e.data)).toList();
      await notificationBox.put('notifications_$userId', notifications.map((e) => e.toJson()).toList());
      await _updateCount(userId, notifications.map((e) => e.toJson()).toList());
      return notifications;
    } catch (_) {
      final cached = notificationBox.get('notifications_$userId', defaultValue: []);
      return (cached as List).map((e) => NotificationModel.fromJson(e)).toList();
    }
  }

  Future<void> syncQueuedNotifications() async {
    final expiry = DateTime.now().subtract(const Duration(days: 30));
    final keys = queueBox.keys.toList();
    for (final key in keys) {
      final Map item = queueBox.get(key);
      final ts = DateTime.tryParse(item['_cachedAt'] ?? '');
      if (ts != null && ts.isBefore(expiry)) {
        await queueBox.delete(key);
        continue;
      }
      try {
        await createNotification(
          item['user_id'] as String,
          item['actor_id'] as String,
          item['action_type'] as String,
          itemId: item['item_id'] as String?,
          itemType: item['item_type'] as String?,
        );
        await queueBox.delete(key);
      } catch (_) {}
    }
  }

  Future<void> markAsRead(String notificationId) async {
    final userId = Get.find<AuthController>().userId;
    if (userId == null) return;
    await databases.updateDocument(
      databaseId: databaseId,
      collectionId: collectionId,
      documentId: notificationId,
      data: {'is_read': true},
    );
    final cached = notificationBox.get('notifications_$userId', defaultValue: []) as List;
    final index = cached.indexWhere((n) => n['\$id'] == notificationId);
    if (index != -1) {
      cached[index]['is_read'] = true;
      await notificationBox.put('notifications_$userId', cached);
      await _updateCount(userId, cached);
    }
  }

  Future<void> _updateCount(String userId, List list) async {
    final count = list.where((n) => !(n['is_read'] as bool)).length;
    await notificationBox.put('unread_count_$userId', count);
    if (count > 0) {
      await FlutterAppBadge.count(count);
    } else {
      await FlutterAppBadge.count(0);
    }
  }
}
