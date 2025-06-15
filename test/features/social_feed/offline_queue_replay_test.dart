import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:appwrite/appwrite.dart';
import 'package:myapp/features/social_feed/services/feed_service.dart';
import 'package:myapp/features/social_feed/models/post_comment.dart';

class _OfflineDatabases extends Databases {
  _OfflineDatabases() : super(Client());
  @override
  Future<Document> createDocument({
    required String databaseId,
    required String collectionId,
    required String documentId,
    required Map<dynamic, dynamic> data,
    List<String>? permissions,
  }) async {
    return Future.error('offline');
  }
}

class _RecordingService extends FeedService {
  final List<String> created = [];
  _RecordingService()
      : super(
          databases: _FakeDatabases(),
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

  @override
  Future<String?> createComment(PostComment comment) async {
    created.add(comment.id);
    return comment.id;
  }
}

class _FakeDatabases extends Databases {
  _FakeDatabases() : super(Client());
  @override
  Future<Document> createDocument({
    required String databaseId,
    required String collectionId,
    required String documentId,
    required Map<dynamic, dynamic> data,
    List<String>? permissions,
  }) async {
    return Document.fromMap({
      '\$id': documentId,
      '\$collectionId': collectionId,
      '\$databaseId': databaseId,
      '\$createdAt': '',
      '\$updatedAt': '',
      '\$permissions': [],
      ...data,
    });
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory dir;
  late FeedService offline;

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
    offline = FeedService(
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
      linkMetadataFunctionId: 'fetch_link_metadata',
    );
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await dir.delete(recursive: true);
  });

  test('queued comment keeps id after sync and updates counts', () async {
    Hive.box('posts').put('p', [
      {'id': 'post', 'comment_count': 0}
    ]);
    final comment = PostComment(
      id: 'offline1',
      postId: 'post',
      userId: 'u',
      username: 'user',
      content: 'hi',
    );
    await offline.createComment(comment);

    final online = _RecordingService();
    await online.syncQueuedActions();

    final cached = Hive.box('posts').get('p') as List;
    expect(cached.first['comment_count'], 1);
    expect(online.created.contains('offline1'), isTrue);
  });
}
