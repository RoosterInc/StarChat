import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:appwrite/appwrite.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:myapp/features/social_feed/widgets/post_card.dart';
import 'package:myapp/features/social_feed/controllers/feed_controller.dart';
import 'package:myapp/features/social_feed/controllers/comments_controller.dart';
import 'package:myapp/features/social_feed/models/feed_post.dart';
import 'package:myapp/features/social_feed/models/post_comment.dart';
import 'package:myapp/features/social_feed/services/feed_service.dart';
import 'package:myapp/features/profile/services/activity_service.dart';

class _FakeService extends FeedService {
  _FakeService()
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
          validateReactionFunctionId: 'validate',
        );

  final List<FeedPost> posts = [];
  final List<PostComment> comments = [];

  @override
  Future<List<FeedPost>> getPosts(String roomId, {List<String> blockedIds = const []}) async {
    return posts.where((p) => p.roomId == roomId).toList();
  }

  @override
  Future<String?> createPost(FeedPost post) async {
    posts.add(post);
    return post.id;
  }

  @override
  Future<List<PostComment>> getComments(
    String postId, {
    int limit = 20,
    String? cursor,
  }) async {
    return comments.where((c) => c.postId == postId).toList();
  }

  @override
  Future<String?> createComment(PostComment comment) async {
    comments.add(comment);
    return comment.id;
  }

  @override
  Future<void> deleteComment(PostComment comment) async {
    comments.removeWhere((c) => c.id == comment.id);
  }
}

class _DummyActivityService extends ActivityService {
  _DummyActivityService()
      : super(databases: Databases(Client()), databaseId: 'db', collectionId: 'act');
  @override
  Future<void> logActivity(String userId, String actionType, {String? itemId, String? itemType}) async {}
}

void main() {
  testWidgets('reaction bar updates on comment add and delete', (tester) async {
    Get.testMode = true;
    Get.put<ActivityService>(_DummyActivityService());
    final service = _FakeService();
    final feed = FeedController(service: service);
    final comments = CommentsController(service: service);
    Get.put(feed);
    Get.put(comments);

    final post = FeedPost(id: 'p1', roomId: 'room', userId: 'u', username: 'user', content: 'post');
    service.posts.add(post);
    await feed.loadPosts('room');

    await tester.pumpWidget(MaterialApp(home: PostCard(post: post)));
    await tester.pump();
    expect(find.text('0'), findsWidgets);

    final comment = PostComment(id: 'c1', postId: 'p1', userId: 'u2', username: 'other', content: 'hi');
    await comments.addComment(comment);
    await tester.pump();
    expect(find.text('1'), findsWidgets);

    await comments.deleteComment('c1');
    await tester.pump();
    expect(find.text('0'), findsWidgets);

    Get.reset();
  });
}
