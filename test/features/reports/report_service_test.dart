import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';

import 'package:myapp/features/reports/services/report_service.dart';
import 'package:myapp/features/reports/models/report_type.dart';

class MockDatabases extends Mock implements Databases {}

void main() {
  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  late MockDatabases databases;
  late ReportService service;

  setUp(() {
    databases = MockDatabases();
    service = ReportService(
      databases: databases,
      databaseId: 'db',
      collectionId: 'reports',
    );
  });

  test('reportPost creates correct document', () async {
    when(() => databases.createDocument(
          databaseId: 'db',
          collectionId: 'reports',
          documentId: any(named: 'documentId'),
          data: any(named: 'data'),
          permissions: null,
        )).thenAnswer((_) async => Document.fromMap({
          '\$id': '1',
          '\$collectionId': 'reports',
          '\$databaseId': 'db',
          '\$createdAt': '',
          '\$updatedAt': '',
          '\$permissions': [],
        }));

    await service.reportPost('u1', 'p1', ReportType.spam, 'bad');

    final captured = verify(() => databases.createDocument(
          databaseId: 'db',
          collectionId: 'reports',
          documentId: any(named: 'documentId'),
          data: captureAny(named: 'data'),
          permissions: null,
        )).captured.single as Map;

    expect(captured['reporter_id'], 'u1');
    expect(captured['reported_post_id'], 'p1');
    expect(captured['report_type'], 'spam');
    expect(captured['description'], 'bad');
    expect(captured['status'], 'pending');
  });

  test('reportPost throws on failure', () async {
    when(() => databases.createDocument(
          databaseId: 'db',
          collectionId: 'reports',
          documentId: any(named: 'documentId'),
          data: any(named: 'data'),
          permissions: null,
        )).thenThrow(Exception('fail'));

    expect(
      () => service.reportPost('u', 'p', ReportType.other, 'd'),
      throwsException,
    );
  });

  test('reportUser creates correct document', () async {
    when(() => databases.createDocument(
          databaseId: 'db',
          collectionId: 'reports',
          documentId: any(named: 'documentId'),
          data: any(named: 'data'),
          permissions: null,
        )).thenAnswer((_) async => Document.fromMap({
          '\$id': '1',
          '\$collectionId': 'reports',
          '\$databaseId': 'db',
          '\$createdAt': '',
          '\$updatedAt': '',
          '\$permissions': [],
        }));

    await service.reportUser('u1', 'u2', ReportType.nudity, 'desc');

    final captured = verify(() => databases.createDocument(
          databaseId: 'db',
          collectionId: 'reports',
          documentId: any(named: 'documentId'),
          data: captureAny(named: 'data'),
          permissions: null,
        )).captured.single as Map;

    expect(captured['reporter_id'], 'u1');
    expect(captured['reported_user_id'], 'u2');
    expect(captured['report_type'], 'nudity');
    expect(captured['description'], 'desc');
    expect(captured['status'], 'pending');
  });

  test('reportUser throws on failure', () async {
    when(() => databases.createDocument(
          databaseId: 'db',
          collectionId: 'reports',
          documentId: any(named: 'documentId'),
          data: any(named: 'data'),
          permissions: null,
        )).thenThrow(Exception('fail'));

    expect(
      () => service.reportUser('u', 'p', ReportType.spam, 'x'),
      throwsException,
    );
  });
}

