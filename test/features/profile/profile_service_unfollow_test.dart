import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:appwrite/appwrite.dart';
import 'package:myapp/features/profile/services/profile_service.dart';

class OfflineDatabases extends Databases {
  OfflineDatabases() : super(Client());

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
    await Hive.openBox('follows');
    service = ProfileService(
      databases: OfflineDatabases(),
      databaseId: 'db',
      profilesCollection: 'profiles',
      followsCollection: 'follows',
      blocksCollection: 'blocks',
    );
    Hive.box('follows').put('u1_u2', {'followed_id': 'u2'});
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await dir.delete(recursive: true);
  });

  test('unfollowUser removes local entry when offline', () async {
    await service.unfollowUser('u1', 'u2');
    expect(Hive.box('follows').containsKey('u1_u2'), isFalse);
  });
}
