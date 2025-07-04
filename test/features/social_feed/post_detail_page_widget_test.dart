import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:appwrite/appwrite.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:myapp/features/social_feed/screens/post_detail_page.dart';
import 'package:myapp/features/social_feed/screens/feed_page.dart';
import 'package:myapp/features/social_feed/controllers/comments_controller.dart';
import 'package:myapp/features/social_feed/controllers/feed_controller.dart';
import 'package:myapp/features/social_feed/models/feed_post.dart';
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
  final List<FeedPost> postStore = [];

  @override
  Future<List<PostComment>> getComments(
    String postId, {
    int limit = 20,
    String? cursor,
  }) async {
    return commentStore.where((c) => c.postId == postId).toList();
  }

  @override
  Future<String?> createComment(PostComment comment) async {
    commentStore.add(comment);
    return null;
  }

  @override
  Future<List<FeedPost>> fetchSortedPosts(
    String sortType, {
    String? roomId,
    String? cursor,
    int limit = 20,
  }) async {
    var list = postStore.where((p) => p.roomId == roomId).toList();
    if (cursor != null) {
      final index = list.indexWhere((p) => p.id == cursor);
      if (index != -1) list = list.sublist(index + 1);
    }
    return list.take(limit).toList();
  }
}

class DelayedFeedService extends TestFeedService {
  @override
  Future<List<FeedPost>> fetchSortedPosts(
    String sortType, {
    String? roomId,
    String? cursor,
    int limit = 20,
  }) {
    return Future.delayed(const Duration(milliseconds: 100), () => []);
  }
}

class DelayedCommentService extends TestFeedService {
  @override
  Future<List<PostComment>> getComments(
    String postId, {
    int limit = 20,
    String? cursor,
  }) {
    return Future.delayed(const Duration(milliseconds: 100), () => []);
  }
}

class CountingService extends TestFeedService {
  int calls = 0;

  @override
  Future<List<PostComment>> getComments(
    String postId, {
    int limit = 20,
    String? cursor,
  }) async {
    calls++;
    return [];
  }

  @override
  Future<PostLike?> getUserLike(String itemId, String userId) async => null;
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

  final post = FeedPost(id: 'p1', roomId: 'r1', userId: 'u1', username: 'user', content: 'hi');

  setUp(() {
    Get.testMode = true;
    Get.put<ActivityService>(StubActivityService());
    Get.put<AuthController>(TestAuthController());
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('shows validation message for overlong comment', (tester) async {
    final service = TestFeedService();
    final controller = CommentsController(service: service);
    Get.put<CommentsController>(controller);
    Get.put<NotificationService>(MockNotificationService());

    await tester.pumpWidget(
      GetMaterialApp(
        theme: MD3ThemeSystem.createTheme(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        home: PostDetailPage(post: post),
      ),
    );

    await tester.pump();
    final longText = 'a' * (commentMaxLength + 1);
    await tester.enterText(find.byType(TextField), longText);
    await tester.tap(find.text('Send'));
    await tester.pump();

    expect(find.text('Comment must be between 1 and 2000 characters.'), findsOneWidget);
    expect(service.commentStore, isEmpty);
  });

  testWidgets('submitting valid comment updates the list', (tester) async {
    final service = TestFeedService();
    final controller = CommentsController(service: service);
    Get.put<CommentsController>(controller);
    Get.put<NotificationService>(MockNotificationService());

    await tester.pumpWidget(
      GetMaterialApp(
        theme: MD3ThemeSystem.createTheme(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        home: PostDetailPage(post: post),
      ),
    );

    await tester.pump();
    await tester.enterText(find.byType(TextField), 'hello');
    await tester.tap(find.text('Send'));
    await tester.pump();

    expect(controller.comments.length, 1);
    expect(find.text('hello'), findsOneWidget);
  });

  testWidgets('HTML entities are unescaped before submission', (tester) async {
    final service = TestFeedService();
    final controller = CommentsController(service: service);
    Get.put<CommentsController>(controller);
    Get.put<NotificationService>(MockNotificationService());

    await tester.pumpWidget(
      GetMaterialApp(
        theme: MD3ThemeSystem.createTheme(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        home: PostDetailPage(post: post),
      ),
    );

    await tester.pump();
    const input = 'hello &amp; world';
    await tester.enterText(find.byType(TextField), input);
    await tester.tap(find.text('Send'));
    await tester.pump();

    expect(service.commentStore.first.content, 'hello & world');
  });

  testWidgets('shows comment skeletons while loading', (tester) async {
    final service = DelayedCommentService();
    final controller = CommentsController(service: service);
    Get.put<CommentsController>(controller);

    await tester.pumpWidget(
      GetMaterialApp(
        theme: MD3ThemeSystem.createTheme(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        home: PostDetailPage(post: post),
      ),
    );

    await tester.pump();
    expect(find.byType(SkeletonLoader), findsWidgets);

    await tester.pump(const Duration(milliseconds: 150));
  });

  testWidgets('displays skeleton loaders while isLoading true', (tester) async {
    final service = DelayedFeedService();
    final controller = FeedController(service: service);
    Get.put<FeedController>(controller);

    await tester.pumpWidget(
      GetMaterialApp(
        theme: MD3ThemeSystem.createTheme(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        home: FeedPage(roomId: 'r1'),
      ),
    );

    await tester.pump();
    expect(find.byType(SkeletonLoader), findsWidgets);

    await tester.pump(const Duration(milliseconds: 150));
  });

  testWidgets('loadComments runs only once on build', (tester) async {
    final service = CountingService();
    final controller = CommentsController(service: service);
    Get.put<CommentsController>(controller);

    await tester.pumpWidget(
      GetMaterialApp(
        theme: MD3ThemeSystem.createTheme(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        home: PostDetailPage(post: post),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(service.calls, 1);
  });

  testWidgets('submitting comment increments feed count', (tester) async {
    final service = TestFeedService();
    final feed = FeedController(service: service);
    service.postStore.add(post);
    await feed.loadPosts('r1');
    Get.put<FeedController>(feed);

    final controller = CommentsController(service: service);
    Get.put<CommentsController>(controller);
    Get.put<NotificationService>(MockNotificationService());

    await tester.pumpWidget(
      GetMaterialApp(
        theme: MD3ThemeSystem.createTheme(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        home: PostDetailPage(post: post),
      ),
    );

    await tester.pump();
    await tester.enterText(find.byType(TextField), 'new comment');
    await tester.tap(find.text('Send'));
    await tester.pump();

    expect(find.text('new comment'), findsOneWidget);
    expect(feed.postCommentCount(post.id), 1);
  });
}
