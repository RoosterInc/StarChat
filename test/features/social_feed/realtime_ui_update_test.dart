import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:appwrite/appwrite.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:myapp/features/social_feed/screens/comment_thread_page.dart';
import 'package:myapp/features/social_feed/controllers/comments_controller.dart';
import 'package:myapp/features/social_feed/models/post_comment.dart';
import 'package:myapp/features/social_feed/services/feed_service.dart';
import 'package:myapp/controllers/auth_controller.dart';
import 'package:myapp/features/profile/services/activity_service.dart';

class _FakeFeedService extends FeedService {
  _FakeFeedService()
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
  final List<PostComment> comments = [];
  @override
  Future<List<PostComment>> getComments(String postId) async {
    return comments.where((c) => c.postId == postId).toList();
  }
}

class _FakeAuth extends AuthController {
  _FakeAuth() {
    userId = 'u1';
    client.setEndpoint('http://localhost').setProject('p');
  }
  @override
  void onInit() {}
  @override
  Future<void> checkExistingSession({bool navigateOnMissing = true}) async {}
}

class _FakeRealtime extends Realtime {
  _FakeRealtime() : super(Client());
  final controller = StreamController<RealtimeMessage>.broadcast();
  @override
  RealtimeSubscription subscribe(List<String> channels) {
    return RealtimeSubscription(
      close: () async {},
      channels: channels,
      controller: controller,
    );
  }
  void emit(RealtimeMessage m) => controller.add(m);
}

class _DummyActivityService extends ActivityService {
  _DummyActivityService()
      : super(databases: Databases(Client()), databaseId: 'db', collectionId: 'a');
  @override
  Future<void> logActivity(String userId, String actionType, {String? itemId, String? itemType}) async {}
}

void main() {
  testWidgets('ui updates from realtime events', (tester) async {
    Get.testMode = true;
    Get.put<ActivityService>(_DummyActivityService());
    final realtime = _FakeRealtime();
    final service = _FakeFeedService();
    final controller = CommentsController(service: service, realtime: realtime);
    final auth = _FakeAuth();
    Get.put<AuthController>(auth);
    Get.put<CommentsController>(controller);

    final root = PostComment(id: 'c1', postId: 'p1', userId: 'u', username: 'root', content: 'root');
    service.comments.add(root);
    await controller.loadComments('p1');

    await tester.pumpWidget(GetMaterialApp(home: CommentThreadPage(rootComment: root)));
    await tester.pump();
    expect(find.text('new'), findsNothing);

    final newComment = PostComment(id: 'new', postId: 'p1', userId: 'u2', username: 'other', content: 'new');
    realtime.emit(RealtimeMessage(events: ['create'], payload: {...newComment.toJson(), '\$id': 'new'}, channels: const [], timestamp: DateTime.now().toIso8601String()));
    await tester.pump();
    expect(find.text('new'), findsOneWidget);

    realtime.emit(RealtimeMessage(events: ['delete'], payload: {'post_id': 'p1', '\$id': 'new'}, channels: const [], timestamp: DateTime.now().toIso8601String()));
    await tester.pump();
    expect(find.text('new'), findsNothing);

    Get.reset();
  });
}
