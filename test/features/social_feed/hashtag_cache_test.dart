import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:myapp/features/social_feed/services/feed_service.dart';

class MemoryDatabases extends Databases {
  MemoryDatabases() : super(Client());

  @override
  Future<DocumentList> listDocuments({
    required String databaseId,
    required String collectionId,
    List<String>? queries,
  }) async {
    return DocumentList(total: 0, documents: []);
  }

  @override
  Future<Document> createDocument({
    required String databaseId,
    required String collectionId,
    required String documentId,
    required Map<dynamic, dynamic> data,
    List<String>? permissions,
  }) async {
    return Document(
      \$id: documentId,
      \$collectionId: collectionId,
      \$databaseId: databaseId,
      \$createdAt: DateTime.now().toIso8601String(),
      \$updatedAt: DateTime.now().toIso8601String(),
      \$permissions: permissions ?? [],
      data: data,
    );
  }
}

void main() {
  late Directory dir;
  late FeedService service;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp();
    Hive.init(dir.path);
    await Hive.openBox('hashtags');
    await Hive.openBox('action_queue');
    service = FeedService(
      databases: MemoryDatabases(),
      storage: Storage(Client()),
      functions: Functions(Client()),
      databaseId: 'db',
      postsCollectionId: 'posts',
      commentsCollectionId: 'comments',
      likesCollectionId: 'likes',
      repostsCollectionId: 'reposts',
      bookmarksCollectionId: 'bookmarks',
      connectivity: Connectivity(),
      linkMetadataFunctionId: 'fetch_link_metadata',
    );
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await dir.delete(recursive: true);
  });

  test('saveHashtags caches tag when online', () async {
    await service.saveHashtags(['flutter']);
    final box = Hive.box('hashtags');
    final cached = box.get('flutter') as Map?;
    expect(cached?['hashtag'], 'flutter');
    expect(cached?['last_used_at'], isNotNull);
    expect(Hive.box('action_queue').isEmpty, isTrue);
  });
}

