import 'package:flutter_test/flutter_test.dart';
import 'package:appwrite/appwrite.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
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
}

void main() {
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
}
