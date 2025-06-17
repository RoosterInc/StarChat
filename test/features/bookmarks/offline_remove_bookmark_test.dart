import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:appwrite/appwrite.dart';
import 'package:myapp/features/social_feed/services/feed_service.dart';

class _OfflineDatabases extends Databases {
  _OfflineDatabases() : super(Client());
  @override
  Future<void> deleteDocument({
    required String databaseId,
    required String collectionId,
    required String documentId,
  }) {
    return Future.error('offline');
  }
}

class _CountingService extends FeedService {
  final List<String> ids = [];
  _CountingService()
      : super(
          databases: Databases(Client()),
          storage: Storage(Client()),
          functions: Functions(Client()),
          databaseId: 'db',
          postsCollectionId: 'posts',
          commentsCollectionId: 'comments',
          likesCollectionId: 'likes',
          repostsCollectionId: 'reposts',
          bookmarksCollectionId: 'bookmarks',
          connectivity: Connectivity(),
          linkMetadataFunctionId: 'link',
        );

  @override
  Future<void> removeBookmark(String bookmarkId) async {
    ids.add(bookmarkId);
  }
}

void main() {
  late Directory dir;
  late FeedService service;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp();
    Hive.init(dir.path);
    await Hive.openBox('posts');
    await Hive.openBox('comments');
    await Hive.openBox('action_queue');
    await Hive.openBox('post_queue');
    await Hive.openBox('bookmarks');
    await Hive.openBox('hashtags');
    await Hive.openBox('preferences');
    service = FeedService(
      databases: _OfflineDatabases(),
      storage: Storage(Client()),
      functions: Functions(Client()),
      databaseId: 'db',
      postsCollectionId: 'posts',
      commentsCollectionId: 'comments',
      likesCollectionId: 'likes',
      repostsCollectionId: 'reposts',
      bookmarksCollectionId: 'bookmarks',
      connectivity: Connectivity(),
      linkMetadataFunctionId: 'link',
    );
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await dir.delete(recursive: true);
  });

  test('removeBookmark queues when offline', () async {
    await expectLater(service.removeBookmark('b1'), throwsA(anything));
    final queue = Hive.box('action_queue');
    expect(queue.isNotEmpty, isTrue);
    final item = queue.getAt(0) as Map?;
    expect(item?['action'], 'remove_bookmark');
    expect(item?['data']['bookmark_id'], 'b1');
  });

  test('syncQueuedActions processes remove_bookmark items', () async {
    await expectLater(service.removeBookmark('b2'), throwsA(anything));
    final counter = _CountingService();
    await counter.syncQueuedActions();
    expect(counter.ids.contains('b2'), isTrue);
    final queue = Hive.box('action_queue');
    expect(queue.isEmpty, isTrue);
  });
}
