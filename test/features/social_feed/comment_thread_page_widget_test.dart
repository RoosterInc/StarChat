import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:appwrite/appwrite.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:myapp/features/social_feed/screens/comment_thread_page.dart';
import 'package:myapp/features/social_feed/controllers/comments_controller.dart';
import 'package:myapp/features/social_feed/models/post_comment.dart';
import 'package:myapp/features/social_feed/services/feed_service.dart';
import 'package:myapp/features/notifications/services/notification_service.dart';
import 'package:myapp/features/profile/services/activity_service.dart';
import 'package:myapp/controllers/auth_controller.dart';
import 'package:myapp/design_system/modern_ui_system.dart';
import 'package:myapp/features/social_feed/utils/comment_validation.dart';

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
          linkMetadataFunctionId: 'fetch_link_metadata',
        );

  final List<PostComment> commentStore = [];

  @override
  Future<List<PostComment>> getComments(String postId) async {
    return commentStore.where((c) => c.postId == postId).toList();
  }

  @override
  Future<void> createComment(PostComment comment) async {
    commentStore.add(comment);
  }
}

class MockNotificationService extends NotificationService {
  MockNotificationService()
      : super(
          databases: Databases(Client()),
          databaseId: 'db',
          collectionId: 'col',
          connectivity: Connectivity(),
        );

  final List<Map<String, dynamic>> calls = [];

  @override
  Future<void> createNotification(
    String userId,
    String actorId,
    String actionType, {
    String? itemId,
    String? itemType,
  }) async {
    calls.add({
      'userId': userId,
      'actorId': actorId,
      'actionType': actionType,
      'itemId': itemId,
      'itemType': itemType,
    });
  }
}

class StubActivityService extends ActivityService {
  StubActivityService()
      : super(databases: Databases(Client()), databaseId: 'db', collectionId: 'act');

  @override
  Future<void> logActivity(String userId, String actionType, {String? itemId, String? itemType}) async {}
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

  final root = PostComment(id: 'c1', postId: 'p1', userId: 'u1', username: 'user', content: 'root');

  setUp(() async {
    Get.testMode = true;
    Get.put<ActivityService>(StubActivityService());
    Get.put<AuthController>(TestAuthController());
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('shows validation message for overlong reply', (tester) async {
    final service = TestFeedService();
    service.commentStore.add(root);
    final controller = CommentsController(service: service);
    await controller.loadComments(root.postId);
    Get.put<CommentsController>(controller);
    Get.put<NotificationService>(MockNotificationService());

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
    final longText = 'a' * (commentMaxLength + 1);
    await tester.enterText(find.byType(TextField), longText);
    await tester.tap(find.text('Send'));
    await tester.pump();

    expect(find.text('Comment must be between 1 and 2000 characters.'), findsOneWidget);
    expect(service.commentStore.length, 1); // only root comment
  });

  testWidgets('submitting valid reply updates the list', (tester) async {
    final service = TestFeedService();
    service.commentStore.add(root);
    final controller = CommentsController(service: service);
    await controller.loadComments(root.postId);
    Get.put<CommentsController>(controller);
    Get.put<NotificationService>(MockNotificationService());

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
    await tester.enterText(find.byType(TextField), 'hello');
    await tester.tap(find.text('Send'));
    await tester.pump();

    expect(controller.comments.length, 2);
    expect(find.text('hello'), findsOneWidget);
  });
}
