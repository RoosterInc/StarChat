import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:appwrite/appwrite.dart';

import 'package:myapp/features/social_feed/controllers/comments_controller.dart';
import 'package:myapp/features/social_feed/models/post_comment.dart';
import 'package:myapp/features/social_feed/services/feed_service.dart';
import 'package:myapp/controllers/auth_controller.dart';

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

  @override
  Future<List<PostComment>> getComments(
    String postId, {
    int limit = 20,
    String? cursor,
  }) async => [];
}

class FakeAuthController extends AuthController {
  FakeAuthController() {
    userId = 'u1';
    client.setEndpoint('http://localhost').setProject('p');
  }

  @override
  void onInit() {}

  @override
  Future<void> checkExistingSession({bool navigateOnMissing = true}) async {}
}

class FakeRealtime extends Realtime {
  FakeRealtime() : super(Client());

  final controller = StreamController<RealtimeMessage>.broadcast();

  @override
  RealtimeSubscription subscribe(List<String> channels) {
    return RealtimeSubscription(
      close: () async {},
      channels: channels,
      controller: controller,
    );
  }

  void emit(RealtimeMessage message) => controller.add(message);
}

void main() {
  test('realtime updates comments list', () async {
    Get.testMode = true;
    final realtime = FakeRealtime();
    final service = FakeFeedService();
    final controller = CommentsController(service: service, realtime: realtime);
    Get.put<AuthController>(FakeAuthController());

    await controller.loadComments('p1');

    final comment = PostComment(
      id: 'c1',
      postId: 'p1',
      userId: 'u',
      username: 'user',
      content: 'hi',
    );

    realtime.emit(
      RealtimeMessage(
        events: ['create'],
        payload: {...comment.toJson(), '\$id': 'c1', 'post_id': 'other'},
        channels: const [],
        timestamp: DateTime.now().toIso8601String(),
      ),
    );

    await Future<void>.delayed(Duration.zero);
    expect(controller.comments.isEmpty, isTrue);

    realtime.emit(
      RealtimeMessage(
        events: ['create'],
        payload: {...comment.toJson(), '\$id': 'c1'},
        channels: const [],
        timestamp: DateTime.now().toIso8601String(),
      ),
    );

    await Future<void>.delayed(Duration.zero);
    expect(controller.comments.length, 1);

    realtime.emit(
      RealtimeMessage(
        events: ['delete'],
        payload: {...comment.toJson(), '\$id': 'c1'},
        channels: const [],
        timestamp: DateTime.now().toIso8601String(),
      ),
    );

    await Future<void>.delayed(Duration.zero);
    expect(controller.comments.isEmpty, isTrue);

    realtime.emit(
      RealtimeMessage(
        events: ['create'],
        payload: {...comment.toJson(), '\$id': 'c1'},
        channels: const [],
        timestamp: DateTime.now().toIso8601String(),
      ),
    );

    await Future<void>.delayed(Duration.zero);
    expect(controller.comments.length, 1);

    controller.disposeSubscription();

    realtime.emit(
      RealtimeMessage(
        events: ['delete'],
        payload: {...comment.toJson(), '\$id': 'c1'},
        channels: const [],
        timestamp: DateTime.now().toIso8601String(),
      ),
    );

    await Future<void>.delayed(Duration.zero);
    expect(controller.comments.length, 1);
  });
}

