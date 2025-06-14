import 'package:flutter_test/flutter_test.dart';
import 'package:appwrite/appwrite.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import 'package:myapp/features/social_feed/controllers/comments_controller.dart';
import 'package:myapp/features/social_feed/models/post_comment.dart';
import 'package:myapp/features/social_feed/services/feed_service.dart';

class PaginatedService extends FeedService {
  PaginatedService()
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
          bookmarksCollectionId: 'bookmarks',
        );

  final List<PostComment> store = [];

  @override
  Future<List<PostComment>> getComments(
    String postId, {
    int limit = 20,
    String? cursor,
  }) async {
    final filtered = store.where((c) => c.postId == postId).toList();
    final start = cursor == null
        ? 0
        : filtered.indexWhere((c) => c.id == cursor) + 1;
    return filtered.skip(start).take(limit).toList();
  }
}

void main() {
  test('loadComments paginates results', () async {
    final service = PaginatedService();
    service.store.addAll(List.generate(
      5,
      (i) => PostComment(
        id: 'c$i',
        postId: 'p1',
        userId: 'u',
        username: 'user',
        content: 'c$i',
      ),
    ));
    final controller = CommentsController(service: service);

    await controller.loadComments('p1', limit: 2);
    expect(controller.comments.length, 2);

    await controller.loadComments('p1', limit: 2, loadMore: true);
    expect(controller.comments.length, 4);

    await controller.loadComments('p1', limit: 2, loadMore: true);
    expect(controller.comments.length, 5);
  });
}
