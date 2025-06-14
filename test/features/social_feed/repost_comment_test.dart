import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:appwrite/appwrite.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:myapp/features/social_feed/controllers/feed_controller.dart';
import 'package:myapp/features/social_feed/models/feed_post.dart';
import 'package:myapp/features/social_feed/models/post_repost.dart';
import 'package:myapp/features/social_feed/services/feed_service.dart';
import 'package:myapp/features/social_feed/widgets/post_card.dart';

class _TrackingService extends FeedService {
  _TrackingService()
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
  int repostCalls = 0;

  @override
  Future<List<FeedPost>> getPosts(String roomId, {List<String> blockedIds = const []}) async {
    return store.where((e) => e.roomId == roomId).toList();
  }

  @override
  Future<String?> createRepost(Map<String, dynamic> repost) async {
    repostCalls += 1;
    return 'r1';
  }

  @override
  Future<PostRepost?> getUserRepost(String postId, String userId) async => null;

  @override
  Future<void> deleteRepost(String repostId, String postId) async {}
}

void main() {
  testWidgets('overlong repost comments show error and do not repost', (tester) async {
    final service = _TrackingService();
    final controller = FeedController(service: service);
    Get.put(controller);

    final post = FeedPost(
      id: '1',
      roomId: 'room',
      userId: 'u1',
      username: 'user',
      content: 'hello',
    );
    service.store.add(post);
    await controller.loadPosts('room');

    await tester.pumpWidget(GetMaterialApp(home: PostCard(post: post)));

    await tester.tap(find.byIcon(Icons.repeat));
    await tester.pumpAndSettle();

    final field = find.byType(TextField);
    await tester.enterText(field, 'a' * 2001);
    await tester.tap(find.text('Repost'));
    await tester.pump();

    expect(find.textContaining('2000'), findsOneWidget);
    expect(controller.isPostReposted('1'), isFalse);
    expect(service.repostCalls, 0);
  });
}
