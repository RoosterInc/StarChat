import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:myapp/features/social_feed/services/feed_service.dart';

class FakeDatabases extends Databases {
  FakeDatabases() : super(Client());

  @override
  Future<models.DocumentList> listDocuments({
    required String databaseId,
    required String collectionId,
    List<String>? queries,
  }) async {
    return models.DocumentList(total: 2, documents: [
      models.Document.fromMap({
        '\$id': '1',
        '\$collectionId': collectionId,
        '\$databaseId': databaseId,
        '\$createdAt': '',
        '\$updatedAt': '',
        '\$permissions': [],
        'room_id': 'room',
        'user_id': 'u1',
        'username': 'user1',
        'content': 'hi',
        'is_deleted': false,
      }),
      models.Document.fromMap({
        '\$id': '2',
        '\$collectionId': collectionId,
        '\$databaseId': databaseId,
        '\$createdAt': '',
        '\$updatedAt': '',
        '\$permissions': [],
        'room_id': 'room',
        'user_id': 'u2',
        'username': 'user2',
        'content': 'bye',
        'is_deleted': true,
      }),
    ]);
  }
}

class OfflineDatabases extends Databases {
  OfflineDatabases() : super(Client());

  @override
  Future<models.DocumentList> listDocuments({
    required String databaseId,
    required String collectionId,
    List<String>? queries,
  }) {
    return Future.error('offline');
  }

  @override
  Future<models.Document> createDocument({
    required String databaseId,
    required String collectionId,
    required String documentId,
    required Map<dynamic, dynamic> data,
    List<String>? permissions,
  }) {
    return Future.error('offline');
  }
}

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp();
    Hive.init(dir.path);
    await Hive.openBox('posts');
    await Hive.openBox('comments');
    await Hive.openBox('action_queue');
    await Hive.openBox('post_queue');
    await Hive.openBox('bookmarks');
    await Hive.openBox('preferences');
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await dir.delete(recursive: true);
  });

  test('fetchSortedPosts excludes deleted posts from API results', () async {
    final service = FeedService(
      databases: FakeDatabases(),
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

    final posts = await service.fetchSortedPosts('most-recent');
    expect(posts.length, 1);
    expect(posts.first.id, '1');
  });

  test('fetchSortedPosts excludes deleted posts from cache when offline', () async {
    final box = Hive.box('posts');
    await box.put('posts_most-recent_home', [
      {
        'id': '1',
        'room_id': 'room',
        'user_id': 'u1',
        'username': 'user1',
        'content': 'hi',
        'is_deleted': false,
      },
      {
        'id': '2',
        'room_id': 'room',
        'user_id': 'u2',
        'username': 'user2',
        'content': 'bye',
        'is_deleted': true,
      },
    ]);

    final service = FeedService(
      databases: OfflineDatabases(),
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

    final posts = await service.fetchSortedPosts('most-recent');
    expect(posts.length, 1);
    expect(posts.first.id, '1');
  });
}
