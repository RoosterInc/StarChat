import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:appwrite/appwrite.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:myapp/features/social_feed/models/feed_post.dart';
import 'package:myapp/features/social_feed/widgets/post_card.dart';
import 'package:myapp/features/social_feed/controllers/feed_controller.dart';
import 'package:myapp/features/social_feed/services/feed_service.dart';
import 'package:myapp/controllers/auth_controller.dart';
import 'package:myapp/features/social_feed/models/post_like.dart';
import 'package:myapp/features/social_feed/models/post_repost.dart';
import 'package:myapp/features/social_feed/screens/repost_page.dart';

class FakeAuthController extends AuthController {
  FakeAuthController({String? id}) {
    userId = id;
  }
  @override
  void onInit() {}
  @override
  Future<void> checkExistingSession({bool navigateOnMissing = true}) async {}
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
          linkMetadataFunctionId: 'link',
        );

  final List<FeedPost> store = [];

  @override
  Future<List<FeedPost>> getPosts(String roomId,
      {List<String> blockedIds = const []}) async {
    return store;
  }

  @override
  Future<PostLike?> getUserLike(String itemId, String userId) async => null;

  @override
  Future<PostRepost?> getUserRepost(String postId, String userId) async => null;
}

void main() {
  testWidgets('unauthenticated users cannot access repost page', (tester) async {
    Get.testMode = true;
    final service = FakeFeedService();
    final controller = FeedController(service: service);
    Get.put(controller);
    Get.put<AuthController>(FakeAuthController());

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
      GetMaterialApp(
        home: Scaffold(body: PostCard(post: post)),
      ),
    );

    await tester.tap(find.byIcon(Icons.repeat));
    await tester.pump();

    expect(find.text('Login required'), findsOneWidget);
    expect(find.byType(RepostPage), findsNothing);
  });
}
