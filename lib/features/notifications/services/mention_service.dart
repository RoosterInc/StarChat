import 'package:appwrite/appwrite.dart';
import 'notification_service.dart';
import '../../../utils/logger.dart';

class MentionService {
  final Databases databases;
  final NotificationService notificationService;
  final String databaseId;
  final String profilesCollectionId;

  MentionService({
    required this.databases,
    required this.notificationService,
    required this.databaseId,
    required this.profilesCollectionId,
  });

  Future<void> notifyMentions(
    List<String> mentions, {
    required String actorId,
    required String itemId,
    required String itemType,
  }) async {
    if (mentions.isEmpty) return;
    for (final name in mentions) {
      try {
        final res = await databases.listDocuments(
          databaseId: databaseId,
          collectionId: profilesCollectionId,
          queries: [Query.equal('username', name)],
        );
        if (res.documents.isNotEmpty) {
          await notificationService.createNotification(
            res.documents.first.data['\$id'],
            actorId,
            'mention',
            itemId: itemId,
            itemType: itemType,
          );
        }
      } catch (e, st) {
        logger.e('Error notifying mentions', error: e, stackTrace: st);
      }
    }
  }
}
