import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:appwrite/appwrite.dart';
import 'package:myapp/features/profile/services/profile_service.dart';

class OfflineDatabases extends Databases {
  OfflineDatabases() : super(Client());

  @override
  Future<Document> createDocument({
    required String databaseId,
    required String collectionId,
    required String documentId,
    required Map<dynamic, dynamic> data,
    List<String>? permissions,
  }) {
    return Future.error('offline');
  }

  @override
  Future<DocumentList> listDocuments({
    required String databaseId,
    required String collectionId,
    List<String>? queries,
  }) {
    return Future.error('offline');
  }

  @override
  Future<void> deleteDocument({
    required String databaseId,
    required String collectionId,
    required String documentId,
  }) {
    return Future.error('offline');
  }
}

void main() {
  late Directory dir;
  late ProfileService service;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp();
    Hive.init(dir.path);
    await Hive.openBox('blocks');
    service = ProfileService(
      databases: OfflineDatabases(),
      databaseId: 'db',
      profilesCollection: 'profiles',
      followsCollection: 'follows',
      blocksCollection: 'blocks',
    );
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await dir.delete(recursive: true);
  });

  test('blockUser stores entry when offline', () async {
    await service.blockUser('u1', 'u2');
    expect(Hive.box('blocks').containsKey('u1_u2'), isTrue);
  });

  test('unblockUser removes entry when offline', () async {
    Hive.box('blocks').put('u1_u2', {'blocked_id': 'u2'});
    await service.unblockUser('u1', 'u2');
    expect(Hive.box('blocks').containsKey('u1_u2'), isFalse);
  });
}
