import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/features/social_feed/models/feed_post.dart';
import 'package:myapp/features/social_feed/widgets/post_card.dart';
import 'package:myapp/shared/utils/time_utils.dart';
import 'package:myapp/features/social_feed/screens/post_detail_page.dart';
import 'package:get/get.dart';
import 'package:myapp/features/social_feed/controllers/feed_controller.dart';
import 'package:myapp/features/social_feed/services/feed_service.dart';
import 'package:appwrite/appwrite.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:myapp/features/social_feed/models/post_like.dart';
import 'package:myapp/features/social_feed/models/post_repost.dart';
import 'package:myapp/controllers/auth_controller.dart';

void main() {
  testWidgets('renders header elements', (tester) async {
    final now = DateTime.now().subtract(const Duration(minutes: 5));
    final post = FeedPost(
      id: '1',
      roomId: 'r1',
      userId: 'u1',
      username: 'user',
      displayName: 'Test User',
      userAvatar: 'http://example.com/a.png',
      content: 'hello',
      createdAt: now,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: PostCard(post: post),
      ),
    );
    expect(find.text('hello'), findsOneWidget);
    expect(find.byType(CircleAvatar), findsOneWidget);
    expect(find.text('Test User'), findsOneWidget);
    expect(find.text('@user'), findsOneWidget);
    expect(find.text(formatRelativeTime(now)), findsOneWidget);
  });

  testWidgets('like button toggles', (tester) async {
    final service = FakeFeedService();
    final controller = FeedController(service: service);
    Get.put(controller);
    final post = FeedPost(
      id: '1',
      roomId: 'r1',
      userId: 'u1',
      username: 'user',
      content: 'hello',
    );
    service.store.add(post);
    await controller.loadPosts('r1');
    await tester.pumpWidget(
      MaterialApp(
        home: PostCard(post: post),
      ),
    );
    await tester.tap(find.byIcon(Icons.favorite_border));
    await tester.pump();
    expect(controller.isPostLiked('1'), isTrue);
  });

  testWidgets('shows repost attribution', (tester) async {
    final service = FakeFeedService();
    final controller = FeedController(service: service);
    Get.put(controller);
    final post = FeedPost(
      id: '1',
      roomId: 'r1',
      userId: 'u1',
      username: 'user',
      content: 'hello',
    );
    service.store.add(post);
    await controller.loadPosts('r1');
    await controller.repostPost('1');
    await tester.pumpWidget(
      MaterialApp(
        home: PostCard(post: post),
      ),
    );
    await tester.pump();
    expect(find.text('Reposted by you'), findsOneWidget);
  });

  testWidgets('repost button label updates when toggled', (tester) async {
    final service = FakeFeedService();
    final controller = FeedController(service: service);
    Get.put(controller);
    final post = FeedPost(
      id: '1',
      roomId: 'r1',
      userId: 'u1',
      username: 'user',
      content: 'hello',
    );
    service.store.add(post);
    await controller.loadPosts('r1');
    await tester.pumpWidget(
      MaterialApp(
        home: PostCard(post: post),
      ),
    );
    expect(find.bySemanticsLabel('Repost'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.repeat));
    await tester.pump();

    expect(find.bySemanticsLabel('Undo Repost'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.repeat));
    await tester.pump();

    expect(find.bySemanticsLabel('Repost'), findsOneWidget);
  });

  testWidgets('tapping card navigates to detail page', (tester) async {
    final post = FeedPost(
      id: '1',
      roomId: 'r1',
      userId: 'u1',
      username: 'user',
      content: 'hello',
    );

    await tester.pumpWidget(
      GetMaterialApp(home: PostCard(post: post)),
    );

    await tester.tap(find.byType(PostCard));
    await tester.pumpAndSettle();

    expect(find.byType(PostDetailPage), findsOneWidget);
  });

  testWidgets('post menu shows owner actions', (tester) async {
    final service = FakeFeedService();
    final controller = FeedController(service: service);
    Get.put(controller);
    Get.put<AuthController>(FakeAuthController(id: 'u1'));
    final post = FeedPost(
      id: '1',
      roomId: 'r1',
      userId: 'u1',
      username: 'user',
      content: 'menu owner',
      createdAt: DateTime.now(),
    );
    service.store.add(post);
    await controller.loadPosts('r1');
    await tester.pumpWidget(
      MaterialApp(
        home: PostCard(post: post),
      ),
    );
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    expect(find.text('Edit Post'), findsOneWidget);
    expect(find.text('Delete Post'), findsOneWidget);
  });

  testWidgets('post menu shows report and user actions', (tester) async {
    final service = FakeFeedService();
    final controller = FeedController(service: service);
    Get.put(controller);
    Get.put<AuthController>(FakeAuthController(id: 'u1'));
    final post = FeedPost(
      id: '1',
      roomId: 'r1',
      userId: 'u2',
      username: 'other',
      content: 'menu test',
      createdAt: DateTime.now(),
    );
    service.store.add(post);
    await controller.loadPosts('r1');
    await tester.pumpWidget(
      MaterialApp(
        home: PostCard(post: post),
      ),
    );
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    expect(find.text('Flag or Report Post'), findsOneWidget);

    // Open the submenu to reveal user actions
    await tester.tap(find.text('@other'));
    await tester.pumpAndSettle();
    expect(find.text('Follow User'), findsOneWidget);
    expect(find.text('Block User'), findsOneWidget);
  });
}

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

  final List<FeedPost> store = [];
  final Map<String, String> likes = {};

  @override
  Future<List<FeedPost>> getPosts(String roomId,
      {List<String> blockedIds = const []}) async {
    return store
        .where((e) => e.roomId == roomId && !blockedIds.contains(e.userId))
        .toList();
  }

  @override
  Future<void> createLike(Map<String, dynamic> like) async {
    likes[like['item_id']] = '1';
  }

  @override
  Future<PostLike?> getUserLike(String itemId, String userId) async {
    final id = likes[itemId];
    return id == null
        ? null
        : PostLike(id: id, itemId: itemId, itemType: 'post', userId: userId);
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
  Future<String?> createRepost(Map<String, dynamic> repost) async => 'r1';

  @override
  Future<void> deleteRepost(String repostId, String postId) async {}

  @override
  Future<PostRepost?> getUserRepost(String postId, String userId) async => null;
}

class FakeAuthController extends AuthController {
  FakeAuthController({String? id}) {
    userId = id;
  }

  @override
  Future<void> checkExistingSession({bool navigateOnMissing = true}) async {}
}
