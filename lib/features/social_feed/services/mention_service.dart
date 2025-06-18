import 'package:appwrite/appwrite.dart';
import 'package:get/get.dart';

import '../../notifications/services/notification_service.dart';
import '../../authentication/controllers/auth_controller.dart';
import '../../../shared/utils/logger.dart';

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
    List<String> mentions,
    String itemId,
    String itemType,
  ) async {
    if (mentions.isEmpty) return;
    final actorId = Get.find<AuthController>().userId;
    if (actorId == null) return;
    try {
      final res = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: profilesCollectionId,
        queries: [Query.equal('username', mentions)],
      );

      for (final doc in res.documents) {
        try {
          await notificationService.createNotification(
            doc.data['\$id'],
            actorId,
            'mention',
            itemId: itemId,
            itemType: itemType,
          );
        } catch (e, st) {
          logger.e('Error notifying mention', error: e, stackTrace: st);
        }
      }
    } catch (e, st) {
      logger.e('Error bulk fetching mentions', error: e, stackTrace: st);
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
}
