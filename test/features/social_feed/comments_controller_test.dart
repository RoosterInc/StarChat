import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/features/social_feed/controllers/comments_controller.dart';
import 'package:myapp/features/social_feed/models/post_comment.dart';
import 'package:myapp/features/social_feed/models/post_like.dart';
import 'package:myapp/features/social_feed/services/feed_service.dart';
import 'package:appwrite/appwrite.dart';

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

  final List<PostComment> store = [];
  final Map<String, String> likes = {};

  @override
  Future<List<PostComment>> getComments(String postId) async {
    return store.where((c) => c.postId == postId).toList();
  }

  @override
  Future<void> createComment(PostComment comment) async {
    store.add(comment);
  }

  @override
  Future<void> createLike(Map<String, dynamic> like) async {
    likes[like['item_id']] = 'l1';
  }

  @override
  Future<void> likeComment(String commentId, String userId) async {
    likes[commentId] = 'l1';
  }

  @override
  Future<void> unlikeComment(String likeId) async {
    likes.removeWhere((key, value) => value == likeId);
  }

  @override
  Future<PostLike?> getUserLike(String itemId, String userId) async {
    final id = likes[itemId];
    return id == null
        ? null
        : PostLike(id: id, itemId: itemId, itemType: 'comment', userId: userId);
  }

  @override
  Future<void> deleteLike(String likeId) async {
    likes.removeWhere((key, value) => value == likeId);
  }
}

void main() {
  test('loadComments returns empty', () async {
    final controller = CommentsController(service: FakeFeedService());
    await controller.loadComments('1');
    expect(controller.comments, isEmpty);
  });

  test('toggleLikeComment updates maps', () async {
    final service = FakeFeedService();
    final controller = CommentsController(service: service);
    final c = PostComment(
      id: '1',
      postId: 'p1',
      userId: 'u',
      username: 'user',
      content: 'hi',
    );
    service.store.add(c);
    await controller.loadComments('p1');
    await controller.toggleLikeComment('1');
    expect(controller.isCommentLiked('1'), isTrue);
    expect(controller.commentLikeCount('1'), 1);
  });

  test('like counts never drop below zero', () async {
    final service = FakeFeedService();
    final controller = CommentsController(service: service);
    final c = PostComment(
      id: '1',
      postId: 'p1',
      userId: 'u',
      username: 'user',
      content: 'hi',
    );
    service.store.add(c);
    service.likes['1'] = 'l1';
    await controller.loadComments('p1');
    await controller.toggleLikeComment('1');
    expect(controller.commentLikeCount('1'), 0);
    await controller.toggleLikeComment('1');
    expect(controller.commentLikeCount('1'), 1);
  });
}
