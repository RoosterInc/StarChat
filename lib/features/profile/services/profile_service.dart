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
  final String blocksCollection;
  final Box profileBox = Hive.box('profiles');
  final Box followsBox = Hive.box('follows');
  final Box blocksBox = Hive.box('blocks');

  ProfileService({
    required this.databases,
    required this.databaseId,
    required this.profilesCollection,
    required this.followsCollection,
    required this.blocksCollection,
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

  Future<void> unfollowUser(String followerId, String followedId) async {
    try {
      final res = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: followsCollection,
        queries: [
          Query.equal('follower_id', followerId),
          Query.equal('followed_id', followedId),
        ],
      );
      for (final doc in res.documents) {
        await databases.deleteDocument(
          databaseId: databaseId,
          collectionId: followsCollection,
          documentId: doc.$id,
        );
      }
      followsBox.delete('${followerId}_$followedId');
    } catch (_) {
      followsBox.delete('${followerId}_$followedId');
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

  Future<void> blockUser(String blockerId, String blockedId) async {
    try {
      await databases.createDocument(
        databaseId: databaseId,
        collectionId: blocksCollection,
        documentId: ID.unique(),
        data: {
          'blocker_id': blockerId,
          'blocked_id': blockedId,
          'created_at': DateTime.now().toIso8601String(),
        },
      );
      blocksBox.put('${blockerId}_$blockedId', {'blocked_id': blockedId});
    } catch (_) {
      blocksBox.put('${blockerId}_$blockedId', {'blocked_id': blockedId});
    }
  }

  Future<void> unblockUser(String blockerId, String blockedId) async {
    try {
      final res = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: blocksCollection,
        queries: [
          Query.equal('blocker_id', blockerId),
          Query.equal('blocked_id', blockedId),
        ],
      );
      for (final doc in res.documents) {
        await databases.deleteDocument(
          databaseId: databaseId,
          collectionId: blocksCollection,
          documentId: doc.$id,
        );
      }
      blocksBox.delete('${blockerId}_$blockedId');
    } catch (_) {
      blocksBox.delete('${blockerId}_$blockedId');
    }
  }

  List<String> getBlockedIds(String blockerId) {
    return blocksBox.keys
        .where((k) => k.toString().startsWith('${blockerId}_'))
        .map((k) => blocksBox.get(k)['blocked_id'] as String)
        .toList();
  }
}

