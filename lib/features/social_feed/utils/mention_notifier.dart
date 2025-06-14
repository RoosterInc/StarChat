import 'package:appwrite/appwrite.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import '../../notifications/services/notification_service.dart';
import '../../../controllers/auth_controller.dart';
import '../../../utils/logger.dart';

/// Sends mention notifications to the provided usernames.
Future<void> notifyMentions(
  List<String> mentions,
  String itemId, {
  required String itemType,
}) async {
  if (mentions.isEmpty || !Get.isRegistered<NotificationService>()) return;
  try {
    final auth = Get.find<AuthController>();
    final dbId = dotenv.env['APPWRITE_DATABASE_ID'] ?? 'StarChat_DB';
    final profilesId = dotenv.env['USER_PROFILES_COLLECTION_ID'] ?? 'user_profiles';

    for (final name in mentions) {
      try {
        final res = await auth.databases.listDocuments(
          databaseId: dbId,
          collectionId: profilesId,
          queries: [Query.equal('username', name)],
        );
        if (res.documents.isNotEmpty) {
          await Get.find<NotificationService>().createNotification(
            res.documents.first.data['\$id'],
            auth.userId ?? '',
            'mention',
            itemId: itemId,
            itemType: itemType,
          );
        }
      } catch (_) {}
    }
  } catch (e, st) {
    logger.e('Error notifying mentions', error: e, stackTrace: st);
    if (Get.context != null) {
      Get.snackbar(
        'Error',
        'Failed to notify mentions',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
