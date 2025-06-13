import 'package:get/get.dart';
import '../../social_feed/services/feed_service.dart';
import '../models/bookmark.dart';
import '../../social_feed/controllers/feed_controller.dart';

class BookmarkController extends GetxController {
  final FeedService service;
  BookmarkController({required this.service});

  final bookmarks = <BookmarkedPost>[].obs;
  final _bookmarkIds = <String, String>{}.obs; // postId -> bookmarkId
  final isLoading = false.obs;

  Future<void> loadBookmarks(String userId) async {
    isLoading.value = true;
    try {
      final data = await service.listBookmarks(userId);
      bookmarks.assignAll(data);
      _bookmarkIds.assignAll({for (final b in data) b.post.id: b.bookmark.id});
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> toggleBookmark(String userId, String postId) async {
    if (_bookmarkIds.containsKey(postId)) {
      final id = _bookmarkIds.remove(postId)!;
      await service.removeBookmark(id);
      bookmarks.removeWhere((b) => b.post.id == postId);
    } else {
      await service.bookmarkPost(userId, postId);
      final bm = await service.getUserBookmark(postId, userId);
      final post = Get.find<FeedController>().posts.firstWhereOrNull((p) => p.id == postId);
      if (bm != null && post != null) {
        _bookmarkIds[postId] = bm.id;
        bookmarks.insert(0, BookmarkedPost(bookmark: bm, post: post));
      } else {
        _bookmarkIds[postId] = 'offline';
      }
    }
  }

  bool isBookmarked(String postId) => _bookmarkIds.containsKey(postId);
}
