import 'package:appwrite/appwrite.dart' as aw;
import '../models/report.dart';

class ModerationService {
  final aw.Databases databases;
  final String databaseId;

  ModerationService({required this.databases, required this.databaseId});

  Future<List<Report>> fetchPendingReports() async {
    final result = await databases.listDocuments(
      databaseId: databaseId,
      collectionId: 'user_reports',
      queries: [aw.Query.equal('status', 'pending')],
    );
    return result.documents.map((doc) => Report.fromJson(doc.data)).toList();
  }

  Future<void> reviewReport(
    String reportId,
    String moderatorId,
    String actionTaken,
  ) async {
    await databases.updateDocument(
      databaseId: databaseId,
      collectionId: 'user_reports',
      documentId: reportId,
      data: {
        'status': 'reviewed',
        'reviewed_by': moderatorId,
        'reviewed_at': DateTime.now().toIso8601String(),
        'action_taken': actionTaken,
      },
    );
  }
}
