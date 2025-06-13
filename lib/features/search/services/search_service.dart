import 'package:appwrite/appwrite.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../profile/models/user_profile.dart';

class SearchService {
  final Databases databases;
  final String databaseId;
  final String profilesCollection;
  final String namesHistoryCollection;
  final Box profileBox = Hive.box('profiles');

  SearchService({
    required this.databases,
    required this.databaseId,
    required this.profilesCollection,
    required this.namesHistoryCollection,
  });

  Future<List<UserProfile>> searchUsers(String query) async {
    try {
      final profiles = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: profilesCollection,
        queries: [Query.search('username', query), Query.search('bio', query)],
      );
      final history = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: namesHistoryCollection,
        queries: [Query.search('username', query)],
      );
      final userIds = history.documents.map((d) => d.data['userId']).toSet();
      List<Document> additional = [];
      if (userIds.isNotEmpty) {
        additional = (await databases.listDocuments(
          databaseId: databaseId,
          collectionId: profilesCollection,
          queries: [Query.equal('\$id', userIds.toList())],
        )).documents;
      }
      final all = [...profiles.documents, ...additional]
          .map((e) => UserProfile.fromJson(e.data))
          .toList();
      for (var p in all) {
        profileBox.put(p.id, p.toJson());
      }
      return all;
    } catch (_) {
      final cached = profileBox.values
          .map((e) => UserProfile.fromJson(e))
          .where((p) => p.username.toLowerCase().contains(query.toLowerCase()) ||
              (p.bio?.toLowerCase().contains(query.toLowerCase()) ?? false))
          .toList();
      return cached;
    }
  }
}
