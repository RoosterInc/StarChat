import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:appwrite/appwrite.dart';
import 'package:myapp/features/social_feed/controllers/comments_controller.dart';
import 'package:myapp/features/social_feed/models/post_comment.dart';
import 'package:myapp/features/social_feed/models/post_like.dart';
import 'package:myapp/features/social_feed/services/feed_service.dart';
import 'package:myapp/features/social_feed/widgets/comment_card.dart';

void main() {
  testWidgets('like comment updates controller', (tester) async {
    final service = _FakeService();
    final controller = CommentsController(service: service);
    Get.put(controller);
    final comment = PostComment(
      id: '1',
      postId: 'p1',
      userId: 'u',
      username: 'user',
      content: 'hi',
    );
    service.store.add(comment);
    await controller.loadComments('p1');
    await tester.pumpWidget(
      MaterialApp(
        home: CommentCard(comment: comment),
      ),
    );
    await tester.tap(find.byIcon(Icons.favorite_border));
    await tester.pump();
    expect(controller.isCommentLiked('1'), isTrue);
  });
}

class _FakeService extends FeedService {
  _FakeService()
      : super(
          databases: Databases(Client()),
          databaseId: 'db',
          postsCollectionId: 'posts',
          commentsCollectionId: 'comments',
          likesCollectionId: 'likes',
          repostsCollectionId: 'reposts',
          connectivity: Connectivity(),
        );

  final List<PostComment> store = [];
  final Map<String, String> likes = {};

  @override
  Future<List<PostComment>> getComments(String postId) async {
    return store.where((e) => e.postId == postId).toList();
  }

  @override
  Future<void> createLike(Map<String, dynamic> like) async {
    likes[like['item_id']] = '1';
  }

  @override
  Future<void> likeComment(String commentId, String userId) async {
    likes[commentId] = '1';
  }

  @override
  Future<void> unlikeComment(String likeId, String commentId) async {
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
  Future<void> deleteLike(
    String likeId, {
    required String itemId,
    required String itemType,
  }) async {
    likes.removeWhere((key, value) => value == likeId);
  }

  @override
  Future<void> createComment(PostComment comment) async {
    store.add(comment);
  }
}
