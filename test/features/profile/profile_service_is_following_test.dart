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
}

void main() {
  late Directory dir;
  late ProfileService service;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp();
    Hive.init(dir.path);
    await Hive.openBox('follows');
    await Hive.openBox('profiles');
    service = ProfileService(
      databases: OfflineDatabases(),
      databaseId: 'db',
      profilesCollection: 'profiles',
      followsCollection: 'follows',
      blocksCollection: 'blocks',
    );
    Hive.box('follows').put('u1_u2', {'followed_id': 'u2'});
    Hive.box('profiles').put('followers_u2', 5);
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await dir.delete(recursive: true);
  });

  test('isFollowing reads from cache when offline', () async {
    final result = await service.isFollowing('u1', 'u2');
    expect(result, isTrue);
  });

  test('getFollowerCount reads from cache when offline', () async {
    final count = await service.getFollowerCount('u2');
    expect(count, 5);
  });
}
