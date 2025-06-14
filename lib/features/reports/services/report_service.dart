import 'package:appwrite/appwrite.dart';
import 'package:get/get.dart';

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
    String reportType,
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
          'report_type': reportType,
          'description': description,
          'status': 'pending',
        },
      );
    } catch (e) {
      throw Exception('Failed to report post: $e');
    }
  }

  Future<void> reportUser(
    String reporterId,
    String reportedUserId,
    String reportType,
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
          'report_type': reportType,
          'description': description,
          'status': 'pending',
        },
      );
    } catch (e) {
      throw Exception('Failed to report user: $e');
    }
  }
}
