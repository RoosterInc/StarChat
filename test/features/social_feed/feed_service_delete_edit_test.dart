import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import 'package:myapp/features/social_feed/services/feed_service.dart';

class FakeDatabases extends Databases {
  FakeDatabases() : super(Client());

  final Map<String, Map<String, dynamic>> docs = {};

  @override
  Future<models.Document> getDocument({
    required String databaseId,
    required String collectionId,
    required String documentId,
    List<String>? queries,
  }) async {
    final data = docs[documentId] ?? {
      '\$createdAt': DateTime.now().toIso8601String(),
    };
    return models.Document.fromMap({
      '\$id': documentId,
      '\$collectionId': collectionId,
      '\$databaseId': databaseId,
      '\$createdAt': data['\$createdAt'],
      '\$updatedAt': '',
      '\$permissions': [],
      ...data,
    });
  }

  @override
  Future<models.Document> updateDocument({
    required String databaseId,
    required String collectionId,
    required String documentId,
    required Map<dynamic, dynamic> data,
    List<String>? permissions,
  }) async {
    final existing = docs[documentId] ?? {};
    docs[documentId] = {
      ...existing,
      ...Map<String, dynamic>.from(data),
    };
    return models.Document.fromMap({
      '\$id': documentId,
      '\$collectionId': collectionId,
      '\$databaseId': databaseId,
      '\$createdAt': existing['\$createdAt'] ?? DateTime.now().toIso8601String(),
      '\$updatedAt': '',
      '\$permissions': [],
      ...docs[documentId]!,
    });
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  late FeedService service;
  late FakeDatabases db;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp();
    Hive.init(dir.path);
    for (final box in [
      'posts',
      'comments',
      'action_queue',
      'post_queue',
      'bookmarks',
      'hashtags',
      'preferences'
    ]) {
      await Hive.openBox(box);
    }

    db = FakeDatabases();
    service = FeedService(
      databases: db,
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

  test('deletePost updates hive cache', () async {
    Hive.box('posts').put('posts_room', [
      {'id': 'p1', 'is_deleted': false}
    ]);

    await service.deletePost('p1');

    final cached = Hive.box('posts').get('posts_room') as List;
    expect(cached.first['is_deleted'], true);
  });

  test('editPost throws when post too old', () async {
    db.docs['old'] = {
      '\$createdAt':
          DateTime.now().subtract(const Duration(minutes: 31)).toIso8601String(),
    };
    await expectLater(
      service.editPost('old', 'c', [], []),
      throwsA(isA<Exception>()),
    );
  });
}

