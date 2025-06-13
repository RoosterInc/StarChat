import 'package:appwrite/appwrite.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_profile.dart';
import '../../notifications/services/notification_service.dart';

class ProfileService {
  final Databases databases;
  final String databaseId;
  final String profilesCollection;
  final String followsCollection;
  final Box profileBox = Hive.box('profiles');
  final Box followsBox = Hive.box('follows');

  ProfileService({
    required this.databases,
    required this.databaseId,
    required this.profilesCollection,
    required this.followsCollection,
  });

  Future<void> followUser(String followerId, String followedId) async {
    try {
      await databases.createDocument(
        databaseId: databaseId,
        collectionId: followsCollection,
        documentId: ID.unique(),
        data: {
          'follower_id': followerId,
          'followed_id': followedId,
          'created_at': DateTime.now().toIso8601String(),
        },
      );
      followsBox.put('${followerId}_$followedId', {'followed_id': followedId});
      await Get.find<NotificationService>()
          .createNotification(followedId, followerId, 'follow');
    } catch (_) {
      followsBox.put('${followerId}_$followedId', {'followed_id': followedId});
    }
  }

  Future<UserProfile> fetchProfile(String userId) async {
    try {
      final res = await databases.getDocument(
        databaseId: databaseId,
        collectionId: profilesCollection,
        documentId: userId,
      );
      final profile = UserProfile.fromJson(res.data);
      await profileBox.put(userId, profile.toJson());
      return profile;
    } catch (_) {
      final cached = profileBox.get(userId);
      if (cached != null) return UserProfile.fromJson(cached);
      rethrow;
    }
  }
}

