import 'package:flutter_test/flutter_test.dart';
import 'package:appwrite/appwrite.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import 'package:myapp/controllers/auth_controller.dart';
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:myapp/features/social_feed/controllers/feed_controller.dart';
import 'package:myapp/features/social_feed/models/feed_post.dart';
import 'package:myapp/features/social_feed/models/post_like.dart';
import 'package:myapp/features/social_feed/models/post_repost.dart';
import 'package:myapp/features/social_feed/services/feed_service.dart';

class FakeFeedService extends FeedService {
  FakeFeedService()
      : super(
          databases: Databases(Client()),
          storage: Storage(Client()),
          functions: Functions(Client()),
          databaseId: 'db',
          postsCollectionId: 'posts',
          commentsCollectionId: 'comments',
          likesCollectionId: 'likes',
          repostsCollectionId: 'reposts',
          connectivity: Connectivity(),
          linkMetadataFunctionId: 'fetch_link_metadata',
        );

  final List<FeedPost> store = [];
  final Map<String, String> likes = {}; // likeId by postId
  final Map<String, String> reposts = {}; // repostId by postId
  final Map<String, int> hashtagCounts = {};

  @override
  Future<List<FeedPost>> getPosts(String roomId,
      {List<String> blockedIds = const []}) async {
    return store
        .where((p) => p.roomId == roomId && !blockedIds.contains(p.userId))
        .toList();
  }

  @override
  Future<void> createPost(FeedPost post) async {
    store.add(post);
  }

  @override
  Future<void> createLike(Map<String, dynamic> like) async {
    likes[like['item_id']] = 'l1';
  }

  @override
  Future<PostLike?> getUserLike(String itemId, String userId) async {
    final id = likes[itemId];
    return id == null
        ? null
        : PostLike(id: id, itemId: itemId, itemType: 'post', userId: userId);
  }

  @override
  Future<void> deleteLike(
    String likeId, {
    required String itemId,
    required String itemType,
  }) async {
    likes.removeWhere((key, value) => value == likeId);
  }

  @override
  Future<String?> createRepost(Map<String, dynamic> repost) async {
    reposts[repost['post_id']] = 'r1';
    return 'r1';
  }

  @override
  Future<void> deleteRepost(String repostId, String postId) async {
    reposts.removeWhere((key, value) => value == repostId);
  }

  @override
  Future<void> saveHashtags(List<String> tags) async {
    for (final t in tags) {
      hashtagCounts[t] = (hashtagCounts[t] ?? 0) + 1;
    }
  }

  @override
  Future<PostRepost?> getUserRepost(String postId, String userId) async {
    final id = reposts[postId];
    return id == null
        ? null
        : PostRepost(id: id, postId: postId, userId: userId);
  }

  @override
  Future<void> editPost(
      String postId, String content, List<String> hashtags, List<String> mentions) async {
    final index = store.indexWhere((p) => p.id == postId);
    if (index != -1) {
      final p = store[index];
      store[index] = FeedPost(
        id: p.id,
        roomId: p.roomId,
        userId: p.userId,
        username: p.username,
        content: content,
        mediaUrls: p.mediaUrls,
        pollId: p.pollId,
        linkUrl: p.linkUrl,
        linkMetadata: p.linkMetadata,
        likeCount: p.likeCount,
        commentCount: p.commentCount,
        repostCount: p.repostCount,
        shareCount: p.shareCount,
        hashtags: hashtags,
        isEdited: true,
      );
    }
  }
}

class TestAuthController extends AuthController {
  final String uid;
  TestAuthController(this.uid);

  @override
  void onInit() {
    super.onInit();
    userId = uid;
  }

  @override
  Future<void> checkExistingSession({bool navigateOnMissing = true}) async {}
}

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
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loadPosts returns empty list', () async {
    final service = FakeFeedService();
    final controller = FeedController(service: service);
    await controller.loadPosts('room');
    expect(controller.posts, isEmpty);
  });

  test('createPost adds to list', () async {
    final service = FakeFeedService();
    final controller = FeedController(service: service);
    final post = FeedPost(
      id: '1',
      roomId: 'room',
      userId: 'u1',
      username: 'user',
      content: 'hello',
    );
    await controller.createPost(post);
    expect(controller.posts.length, 1);
  });

  test('toggleLikePost updates maps', () async {
    final service = FakeFeedService();
    final controller = FeedController(service: service);
    service.store.add(
      FeedPost(
        id: '1',
        roomId: 'room',
        userId: 'u1',
        username: 'user',
        content: 'text',
      ),
    );
    await controller.loadPosts('room');
    await controller.toggleLikePost('1');
    expect(controller.isPostLiked('1'), isTrue);
    expect(controller.postLikeCount('1'), 1);
    await controller.toggleLikePost('1');
    expect(controller.isPostLiked('1'), isFalse);
  });

  test('toggleLikePost offline still updates locally', () async {
    class OfflineLikeService extends FakeFeedService {
      @override
      Future<PostLike?> getUserLike(String itemId, String userId) {
        return Future.error('offline');
      }
    }

    final service = OfflineLikeService();
    final controller = FeedController(service: service);
    service.store.add(
      FeedPost(
        id: '1',
        roomId: 'room',
        userId: 'u1',
        username: 'user',
        content: 'text',
      ),
    );
    await controller.loadPosts('room');
    await controller.toggleLikePost('1');
    expect(controller.isPostLiked('1'), isTrue);
    expect(controller.postLikeCount('1'), 1);
  });

  test('post like count never below zero', () async {
    final service = FakeFeedService();
    final controller = FeedController(service: service);
    service.store.add(
      FeedPost(
        id: '2',
        roomId: 'room',
        userId: 'u1',
        username: 'user',
        content: 'text',
      ),
    );
    service.likes['2'] = 'l1';
    await controller.loadPosts('room');
    await controller.toggleLikePost('2');
    expect(controller.postLikeCount('2'), 0);
    await controller.toggleLikePost('2');
    expect(controller.postLikeCount('2'), 1);
  });

  test('toggleLikePost offline unlike updates count', () async {
    class OfflineDeleteService extends FakeFeedService {
      @override
      Future<void> deleteLike(String likeId, {required String itemId, required String itemType}) {
        return Future.error('offline');
      }
    }

    final service = OfflineDeleteService();
    final controller = FeedController(service: service);
    service.store.add(
      FeedPost(
        id: '1',
        roomId: 'room',
        userId: 'u1',
        username: 'user',
        content: 'text',
        likeCount: 1,
      ),
    );
    service.likes['1'] = 'l1';
    await controller.loadPosts('room');
    await controller.toggleLikePost('1');
    expect(controller.isPostLiked('1'), isFalse);
    expect(controller.postLikeCount('1'), 0);
  });

  test('repostPost stores id and increases count', () async {
    final service = FakeFeedService();
    final controller = FeedController(service: service);
    service.store.add(
      FeedPost(
        id: '1',
        roomId: 'room',
        userId: 'u1',
        username: 'user',
        content: 'hello',
      ),
    );
    await controller.loadPosts('room');
    await controller.repostPost('1', 'nice');
    expect(controller.postRepostCount('1'), 1);
    expect(controller.isPostReposted('1'), isTrue);
  });

  test('undoRepost decreases count', () async {
    final service = FakeFeedService();
    final controller = FeedController(service: service);
    service.store.add(
      FeedPost(
        id: '1',
        roomId: 'room',
        userId: 'u1',
        username: 'user',
        content: 'hello',
      ),
    );
    await controller.loadPosts('room');
    await controller.repostPost('1');
    await controller.undoRepost('1');
    expect(controller.isPostReposted('1'), isFalse);
    expect(controller.postRepostCount('1'), 0);
  });

  test('undoRepost offline queues action and retains id', () async {
    class OfflineService extends FeedService {
      OfflineService()
          : super(
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

      @override
      Future<String?> createRepost(Map<String, dynamic> repost) async => 'r1';
    }

    final dir = await Directory.systemTemp.createTemp();
    Hive.init(dir.path);
    await Hive.openBox('action_queue');

    Get.testMode = true;
    Get.put<AuthController>(TestAuthController('u1'));
    final service = OfflineService();
    final controller = FeedController(service: service);
    await controller.repostPost('1');

    await controller.undoRepost('1');

    expect(controller.isPostReposted('1'), isTrue);
    expect(controller.postRepostCount('1'), 1);

    final queue = Hive.box('action_queue');
    expect(queue.isNotEmpty, isTrue);
    final item = queue.getAt(0) as Map?;
    expect(item?['action'], 'delete_repost');
    expect(item?['id'], 'r1');
    await Hive.deleteFromDisk();
    await dir.delete(recursive: true);
    Get.delete<AuthController>();
  });

  test('editPost updates content', () async {
    final service = FakeFeedService();
    final controller = FeedController(service: service);
    final post = FeedPost(
      id: '1',
      roomId: 'room',
      userId: 'u1',
      username: 'user',
      content: 'hello',
    );
    service.store.add(post);
    await controller.loadPosts('room');
    await controller.editPost('1', 'updated', [], []);
    expect(controller.posts.first.content, 'updated');
    expect(controller.posts.first.isEdited, isTrue);
  });

  test('editPost saves new hashtags without duplicates', () async {
    final service = FakeFeedService();
    final controller = FeedController(service: service);
    final post = FeedPost(
      id: '1',
      roomId: 'room',
      userId: 'u1',
      username: 'user',
      content: 'hello #old',
      hashtags: ['old'],
    );
    service.store.add(post);
    await controller.loadPosts('room');
    await controller.editPost(
      '1',
      'updated #old #new #new',
      ['old', 'new', 'new'],
      [],
    );
    expect(service.hashtagCounts['new'], 1);
    expect(service.hashtagCounts.containsKey('old'), isFalse);
  });
  test('createPost trims hashtags to 10', () async {
    final service = FakeFeedService();
    final controller = FeedController(service: service);
    final tags = List.generate(15, (i) => 'tag\$i');
    final post = FeedPost(
      id: '2',
      roomId: 'room',
      userId: 'u2',
      username: 'name',
      content: 'post',
      hashtags: tags,
    );
    await controller.createPost(post);
    expect(service.store.first.hashtags.length, 10);
    expect(controller.posts.first.hashtags.length, 10);
  });

  test('createPostWithImage trims hashtags', () async {
    final dir = await Directory.systemTemp.createTemp();
    final file = File('${dir.path}/img.jpg');
    await file.writeAsBytes(List.filled(10, 0));
    final service = FakeFeedService();
    final controller = FeedController(service: service);
    final tags = List.generate(12, (i) => 't\$i');
    await controller.createPostWithImage('u', 'user', 'c', 'room', file, tags, []);
    expect(service.store.first.hashtags.length, 10);
    expect(controller.posts.first.hashtags.length, 10);
    await dir.delete(recursive: true);
  });

  test('createPostWithLink trims hashtags', () async {
    final service = FakeFeedService();
    final controller = FeedController(service: service);
    final tags = List.generate(11, (i) => 'x\$i');
    await controller.createPostWithLink(
      'u',
      'user',
      'c',
      'room',
      'https://x.com',
      tags,
      [],
    );
    expect(service.store.first.hashtags.length, 10);
    expect(controller.posts.first.hashtags.length, 10);
  });
}
