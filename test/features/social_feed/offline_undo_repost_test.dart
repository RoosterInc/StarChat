import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:appwrite/appwrite.dart';
import 'package:myapp/features/social_feed/controllers/feed_controller.dart';
import 'package:myapp/features/social_feed/services/feed_service.dart';
import 'package:myapp/features/social_feed/models/feed_post.dart';

class _OfflineDatabases extends Databases {
  _OfflineDatabases() : super(Client());

  @override
  Future<void> deleteDocument({
    required String databaseId,
    required String collectionId,
    required String documentId,
  }) async {
    throw 'offline';
  }
}

class _OfflineService extends FeedService {
  _OfflineService()
      : super(
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

  final List<FeedPost> store = [];
  final Map<String, String> reposts = {};

  @override
  Future<List<FeedPost>> getPosts(String roomId, {List<String> blockedIds = const []}) async {
    return store.where((e) => e.roomId == roomId).toList();
  }

  @override
  Future<String?> createRepost(Map<String, dynamic> repost) async {
    reposts[repost['post_id']] = 'r1';
    return 'r1';
  }

  @override
  Future<void> deleteRepost(String repostId) async {
    final box = Hive.box('action_queue');
    if (box.length >= 50) {
      final key = box.keys.first;
      await box.delete(key);
    }
    await box.add({'action': 'delete_repost', 'repost_id': repostId});
  }
}

void main() {
  late Directory dir;
  late FeedController controller;
  late _OfflineService service;

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
    service = _OfflineService();
    controller = FeedController(service: service);
    Get.put(controller);
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await dir.delete(recursive: true);
  });

  test('undoRepost queues delete when offline', () async {
    final post = FeedPost(
      id: '1',
      roomId: 'room',
      userId: 'u1',
      username: 'user',
      content: 'hi',
    );
    service.store.add(post);
    await controller.loadPosts('room');
    await controller.repostPost('1');
    final queue = Hive.box('action_queue');
    expect(queue.isEmpty, isTrue);
    await controller.undoRepost('1');
    expect(controller.isPostReposted('1'), isFalse);
    expect(queue.isNotEmpty, isTrue);
  });
}
