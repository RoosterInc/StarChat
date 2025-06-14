import 'package:appwrite/appwrite.dart';
import '../../../utils/logger.dart';
import '../models/report_type.dart';

class ReportService {
  final Databases databases;
  final String databaseId;
  final String collectionId;

  ReportService({
    required this.databases,
    required this.databaseId,
    required this.collectionId,
  });

  Future<void> reportPost(
    String reporterId,
    String postId,
    ReportType reportType,
    String description,
  ) async {
    try {
      await databases.createDocument(
        databaseId: databaseId,
        collectionId: collectionId,
        documentId: ID.unique(),
        data: {
          'reporter_id': reporterId,
          'reported_post_id': postId,
          'report_type': reportType.name,
          'description': description,
          'status': 'pending',
        },
      );
    } catch (e, st) {
      logger.e('Failed to report post', error: e, stackTrace: st);
      throw Exception('Failed to report post: $e');
    }
  }

  Future<void> reportUser(
    String reporterId,
    String reportedUserId,
    ReportType reportType,
    String description,
  ) async {
    try {
      await databases.createDocument(
        databaseId: databaseId,
        collectionId: collectionId,
        documentId: ID.unique(),
        data: {
          'reporter_id': reporterId,
          'reported_user_id': reportedUserId,
          'report_type': reportType.name,
          'description': description,
          'status': 'pending',
        },
      );
    } catch (e, st) {
      logger.e('Failed to report user', error: e, stackTrace: st);
      throw Exception('Failed to report user: $e');
    }
  }
}
