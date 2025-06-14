import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:appwrite/appwrite.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:myapp/features/social_feed/screens/post_detail_page.dart';
import 'package:myapp/features/social_feed/screens/comment_thread_page.dart';
import 'package:myapp/features/social_feed/models/feed_post.dart';
import 'package:myapp/features/social_feed/models/post_comment.dart';
import 'package:myapp/features/social_feed/controllers/comments_controller.dart';
import 'package:myapp/features/social_feed/services/feed_service.dart';
import 'package:myapp/controllers/auth_controller.dart';

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

  @override
  Future<List<PostComment>> getComments(String postId) async => [];

  @override
  Future<String?> createComment(PostComment comment) async {
    return null;
  }
}

class _TestAuthController extends AuthController {
  @override
  void onInit() {
    userId = 'u1';
    username.value = 'tester';
  }

  @override
  Future<void> checkExistingSession({bool navigateOnMissing = true}) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.testMode = true;
    Get.put<AuthController>(_TestAuthController());
    Get.put<CommentsController>(CommentsController(service: _FakeService()));
  });

  tearDown(Get.reset);

  testWidgets('PostDetailPage send button has semantics', (tester) async {
    final post = FeedPost(
      id: 'p1',
      roomId: 'r1',
      userId: 'u1',
      username: 'tester',
      content: 'content',
    );
    await tester.pumpWidget(MaterialApp(home: PostDetailPage(post: post)));
    expect(find.bySemanticsLabel('Send comment'), findsOneWidget);
  });

  testWidgets('CommentThreadPage send button has semantics', (tester) async {
    final comment = PostComment(
      id: 'c1',
      postId: 'p1',
      userId: 'u1',
      username: 'tester',
      content: 'hi',
    );
    await tester.pumpWidget(MaterialApp(home: CommentThreadPage(rootComment: comment)));
    expect(find.bySemanticsLabel('Send reply'), findsOneWidget);
  });
}
