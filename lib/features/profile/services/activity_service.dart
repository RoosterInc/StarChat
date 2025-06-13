import 'package:appwrite/appwrite.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ActivityService {
  final Databases databases;
  final String databaseId;
  final String collectionId;
  final Box activityBox = Hive.box('activities');

  ActivityService({
    required this.databases,
    required this.databaseId,
    required this.collectionId,
  });

  Future<void> logActivity(
    String userId,
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
          'action_type': actionType,
          'item_id': itemId,
          'item_type': itemType,
          'created_at': DateTime.now().toIso8601String(),
        },
      );
      activityBox.put(doc.$id, doc.data);
    } catch (_) {
      activityBox.add({
        'user_id': userId,
        'action_type': actionType,
        'item_id': itemId,
        'item_type': itemType,
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<List<Map<String, dynamic>>> fetchActivities(String userId) async {
    try {
      final res = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: collectionId,
        queries: [
          Query.equal("user_id", userId),
          Query.orderDesc("created_at"),
          Query.limit(50),
        ],
      );
      final logs = res.documents.map((e) => e.data).toList();
      await activityBox.put("activities_" + userId, logs);
      return logs.cast<Map<String, dynamic>>();
    } catch (_) {
      final cached = activityBox.get("activities_" + userId, defaultValue: []);
      return (cached as List).cast<Map<String, dynamic>>();
    }
  }
}
