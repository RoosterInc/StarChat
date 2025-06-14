import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:appwrite/appwrite.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:myapp/features/social_feed/screens/comment_thread_page.dart';
import 'package:myapp/features/social_feed/controllers/comments_controller.dart';
import 'package:myapp/features/social_feed/models/post_comment.dart';
import 'package:myapp/features/social_feed/services/feed_service.dart';
import 'package:myapp/features/social_feed/widgets/comment_card.dart';
import 'package:myapp/design_system/modern_ui_system.dart';
import 'package:myapp/controllers/auth_controller.dart';

class TestFeedService extends FeedService {
  TestFeedService()
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

  final List<PostComment> commentStore = [];

  @override
  Future<List<PostComment>> getComments(
    String postId, {
    int limit = 20,
    String? cursor,
  }) async {
    return commentStore.where((c) => c.postId == postId).toList();
  }
}

class RecordingCommentsController extends CommentsController {
  RecordingCommentsController({required super.service});

  final List<String> calls = [];

  @override
  Future<void> toggleLikeComment(String commentId) async {
    calls.add('like:$commentId');
  }

  @override
  Future<void> deleteComment(String commentId) async {
    calls.add('delete:$commentId');
  }
}

class TestAuthController extends AuthController {
  TestAuthController() {
    account = Account(client);
    databases = Databases(client);
    storage = Storage(client);
    userId = 'u1';
    username.value = 'tester';
  }

  @override
  Future<void> checkExistingSession({bool navigateOnMissing = true}) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final root = PostComment(
    id: 'c1',
    postId: 'p1',
    userId: 'u1',
    username: 'user1',
    content: 'root',
  );
  final reply1 = PostComment(
    id: 'c2',
    postId: 'p1',
    userId: 'u2',
    username: 'user2',
    parentId: 'c1',
    content: 'reply1',
  );
  final reply2 = PostComment(
    id: 'c3',
    postId: 'p1',
    userId: 'u3',
    username: 'user3',
    parentId: 'c2',
    content: 'reply2',
  );

  setUp(() {
    Get.testMode = true;
    Get.put<AuthController>(TestAuthController());
  });

  tearDown(Get.reset);

  testWidgets('nested comments show and actions call controller', (tester) async {
    final service = TestFeedService();
    service.commentStore.addAll([root, reply1, reply2]);
    final controller = RecordingCommentsController(service: service);
    await controller.loadComments(root.postId);
    Get.put<CommentsController>(controller);

    await tester.pumpWidget(
      GetMaterialApp(
        theme: MD3ThemeSystem.createTheme(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        home: CommentThreadPage(rootComment: root),
      ),
    );

    await tester.pump();

    expect(find.text('reply1'), findsOneWidget);
    expect(find.text('reply2'), findsOneWidget);

    final rootCard = find.byWidgetPredicate(
      (w) => w is CommentCard && w.comment.id == root.id,
    );
    final likeButton = find.descendant(
      of: rootCard,
      matching: find.bySemanticsLabel('Like comment'),
    );
    await tester.tap(likeButton);
    await tester.pump();

    await tester.tap(find.bySemanticsLabel('Delete comment'));
    await tester.pump();
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pump();

    expect(controller.calls, contains('like:${root.id}'));
    expect(controller.calls, contains('delete:${root.id}'));
  });
}
