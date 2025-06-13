import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:myapp/features/social_feed/services/feed_service.dart';
import 'package:appwrite/appwrite.dart' as aw;

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
  Future<Document> createDocument({
    required String databaseId,
    required String collectionId,
    required String documentId,
    required Map<dynamic, dynamic> data,
    List<String>? permissions,
  }) {
    return Future.error('offline');
  }
}

class OfflineStorage extends Storage {
  OfflineStorage() : super(Client());

  @override
  Future<File> createFile({
    required String bucketId,
    required String fileId,
    required InputFile file,
    List<String>? permissions,
    bool? onProgress,
  }) {
    return Future.error('offline');
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
    await Hive.openBox('preferences');
    service = FeedService(
      databases: OfflineDatabases(),
      storage: OfflineStorage(),
      databaseId: 'db',
      postsCollectionId: 'posts',
      commentsCollectionId: 'comments',
      likesCollectionId: 'likes',
      repostsCollectionId: 'reposts',
      bookmarksCollectionId: 'bookmarks',
      connectivity: Connectivity(),
    );
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await dir.delete(recursive: true);
  });

  test('getPosts returns cached posts when offline', () async {
    final box = Hive.box('posts');
    await box.put('posts_room', [
      {
        'id': '1',
        'room_id': 'room',
        'user_id': 'u',
        'username': 'name',
        'content': 'hi',
        '_cachedAt': DateTime.now().toIso8601String(),
      }
    ]);
    final posts = await service.getPosts('room');
    expect(posts, isNotEmpty);
    expect(posts.first.content, 'hi');
  });

  test('createLike queues when offline', () async {
    await service.createLike({'item_id': '1', 'item_type': 'post', 'user_id': 'u'});
    final queue = Hive.box('action_queue');
    expect(queue.isNotEmpty, isTrue);
  });

  test('createPostWithImage queues when offline', () async {
    final file = File('${dir.path}/img.jpg');
    await file.writeAsBytes(List.filled(10, 0));
    await service.createPostWithImage('u', 'name', 'hi', 'room', file,
        hashtags: ['tag']);
    final queue = Hive.box('post_queue');
    expect(queue.isNotEmpty, isTrue);
  });
  test('createPostWithLink queues when offline', () async {
    await service.createPostWithLink('u', 'name', 'hi', 'room', 'https://x.com',
        hashtags: ['tag']);
    final queue = Hive.box('action_queue');
    expect(queue.isNotEmpty, isTrue);
  });

  test('saveHashtags queues when offline', () async {
    await service.saveHashtags(['tag']);
    final queue = Hive.box('action_queue');
    expect(queue.isNotEmpty, isTrue);
  });

  test('bookmarkPost queues when offline', () async {
    await service.bookmarkPost('u', '1');
    final queue = Hive.box('action_queue');
    expect(queue.isNotEmpty, isTrue);
  });

}
