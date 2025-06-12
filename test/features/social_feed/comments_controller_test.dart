import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/features/social_feed/controllers/comments_controller.dart';
import 'package:myapp/features/social_feed/models/post_comment.dart';
import 'package:myapp/features/social_feed/services/feed_service.dart';
import 'package:appwrite/appwrite.dart';

class FakeFeedService extends FeedService {
  FakeFeedService()
      : super(
          databases: Databases(Client()),
          databaseId: 'db',
          postsCollectionId: 'posts',
          commentsCollectionId: 'comments',
        );

  final List<PostComment> store = [];

  @override
  Future<List<PostComment>> getComments(String postId) async {
    return store.where((c) => c.postId == postId).toList();
  }
}

void main() {
  test('loadComments returns empty', () async {
    final controller = CommentsController(service: FakeFeedService());
    await controller.loadComments('1');
    expect(controller.comments, isEmpty);
  }, skip: true);
}
