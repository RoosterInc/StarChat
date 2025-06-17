import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:appwrite/appwrite.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:myapp/features/bookmarks/controllers/bookmark_controller.dart';
import 'package:myapp/features/bookmarks/models/bookmark.dart';
import 'package:myapp/features/social_feed/models/feed_post.dart';
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
          bookmarksCollectionId: 'bookmarks',
          connectivity: Connectivity(),
          linkMetadataFunctionId: 'link',
          validateReactionFunctionId: 'validate',
        );

  final List<FeedPost> posts = [];
  final Map<String, String> bms = {};

  @override
  Future<List<BookmarkedPost>> listBookmarks(String userId) async {
    return bms.entries
        .map(
          (e) => BookmarkedPost(
            bookmark: Bookmark(
                id: e.value,
                postId: e.key,
                userId: userId,
                createdAt: DateTime.now()),
            post: posts.firstWhere((p) => p.id == e.key),
          ),
        )
        .toList();
  }

  @override
  Future<void> bookmarkPost(String userId, String postId) async {
    bms[postId] = 'b1';
  }

  @override
  Future<void> removeBookmark(String bookmarkId) async {
    bms.removeWhere((key, value) => value == bookmarkId);
  }

  @override
  Future<Bookmark?> getUserBookmark(String postId, String userId) async {
    final id = bms[postId];
    return id == null
        ? null
        : Bookmark(
            id: id,
            postId: postId,
            userId: userId,
            createdAt: DateTime.now(),
          );
  }

  @override
  Future<List<FeedPost>> fetchSortedPosts(
    String sortType, {
    String? roomId,
    String? cursor,
    int limit = 20,
  }) async {
    final list = roomId == null
        ? posts
        : posts.where((p) => p.roomId == roomId).toList();
    if (cursor != null) {
      final index = list.indexWhere((p) => p.id == cursor);
      if (index != -1) return list.sublist(index + 1).take(limit).toList();
    }
    return list.take(limit).toList();
  }
}

class OfflineGetBookmarkService extends FakeFeedService {
  @override
  Future<Bookmark?> getUserBookmark(String postId, String userId) {
    return Future.error('offline');
  }
}

class OfflineRemoveService extends FakeFeedService {
  @override
  Future<void> removeBookmark(String bookmarkId) {
    return Future.error('offline');
  }
}

class _StubFeedController extends FeedController {
  final List<FeedPost> _list;
  _StubFeedController(this._list) : super(service: FakeFeedService());

  @override
  List<FeedPost> get posts => _list;
}

void main() {
  Get.testMode = true;

  test('toggleBookmark updates map', () async {
    final service = FakeFeedService();
    service.posts.add(FeedPost(
      id: '1',
      roomId: 'r',
      userId: 'u',
      username: 'n',
      content: 'c',
    ));
    final controller = BookmarkController(service: service);
    await controller.toggleBookmark('u', '1');
    expect(controller.isBookmarked('1'), isTrue);
    await controller.toggleBookmark('u', '1');
    expect(controller.isBookmarked('1'), isFalse);
  });

  test('bookmark offline sets offline id', () async {
    final service = OfflineGetBookmarkService();
    service.posts.add(
      FeedPost(id: '1', roomId: 'r', userId: 'u', username: 'n', content: 'c'),
    );
    final controller = BookmarkController(service: service);
    await controller.toggleBookmark('u', '1');
    expect(controller.isBookmarked('1'), isTrue);
  });

  test('unbookmark failure reverts state', () async {
    final service = OfflineRemoveService();
    service.posts.add(
      FeedPost(id: '1', roomId: 'r', userId: 'u', username: 'n', content: 'c'),
    );
    final controller = BookmarkController(service: service);
    await controller.toggleBookmark('u', '1');
    expect(controller.isBookmarked('1'), isTrue);
    await controller.toggleBookmark('u', '1');
    expect(controller.isBookmarked('1'), isTrue);
  });

  test('loadBookmarks populates bookmarks list', () async {
    final dir = await Directory.systemTemp.createTemp();
    Hive.init(dir.path);
    await Hive.openBox('posts');
    await Hive.openBox('comments');
    await Hive.openBox('action_queue');
    await Hive.openBox('post_queue');
    await Hive.openBox('bookmarks');
    await Hive.openBox('hashtags');
    await Hive.openBox('preferences');

    final service = FakeFeedService();
    service.posts.add(
      FeedPost(id: '1', roomId: 'r', userId: 'u', username: 'n', content: 'c'),
    );
    service.bms['1'] = 'b1';
    final controller = BookmarkController(service: service);
    await controller.loadBookmarks('u');

    expect(controller.bookmarks.length, 1);
    expect(controller.isBookmarked('1'), isTrue);

    await Hive.deleteFromDisk();
    await dir.delete(recursive: true);
  });

  test('toggleBookmark updates bookmark list when feed available', () async {
    final dir = await Directory.systemTemp.createTemp();
    Hive.init(dir.path);
    await Hive.openBox('posts');
    await Hive.openBox('comments');
    await Hive.openBox('action_queue');
    await Hive.openBox('post_queue');
    await Hive.openBox('bookmarks');
    await Hive.openBox('hashtags');
    await Hive.openBox('preferences');

    final service = FakeFeedService();
    final post = FeedPost(
      id: '1',
      roomId: 'r',
      userId: 'u',
      username: 'n',
      content: 'c',
    );
    service.posts.add(post);
    final feed = _StubFeedController([post]);
    Get.put<FeedController>(feed);

    final controller = BookmarkController(service: service);
    await controller.toggleBookmark('u', '1');
    expect(controller.bookmarks.length, 1);
    expect(controller.bookmarks.first.post.id, '1');

    await controller.toggleBookmark('u', '1');
    expect(controller.bookmarks, isEmpty);

    await Hive.deleteFromDisk();
    await dir.delete(recursive: true);
    Get.reset();
  });
}
