import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:appwrite/appwrite.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';

import 'package:myapp/design_system/modern_ui_system.dart';
import 'package:myapp/features/social_feed/controllers/feed_controller.dart';
import 'package:myapp/features/social_feed/models/feed_post.dart';
import 'package:myapp/features/social_feed/screens/edit_post_page.dart';
import 'package:myapp/features/social_feed/services/feed_service.dart';
import 'package:myapp/features/social_feed/services/mention_service.dart';
import 'package:myapp/features/notifications/services/notification_service.dart';
import 'package:myapp/controllers/auth_controller.dart';

class DummyFeedService extends FeedService {
  DummyFeedService()
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

  Map<String, dynamic>? lastCall;

  @override
  Future<void> editPost(
    String postId,
    String content,
    List<String> hashtags,
    List<String> mentions,
  ) async {
    lastCall = {
      'id': postId,
      'content': content,
      'hashtags': hashtags,
      'mentions': mentions,
    };
  }

  @override
  Future<void> saveHashtags(List<String> tags) async {}
}

class RecordingNotificationService extends NotificationService {
  RecordingNotificationService()
      : super(
          databases: Databases(Client()),
          databaseId: 'db',
          collectionId: 'notifications',
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

class RecordingMentionService extends MentionService {
  RecordingMentionService({required super.databases, required super.notificationService, required super.databaseId, required super.profilesCollectionId});

  final List<Map<String, dynamic>> calls = [];

  @override
  Future<void> notifyMentions(
    List<String> mentions,
    String itemId,
    String itemType,
  ) async {
    calls.add({
      'mentions': mentions,
      'itemId': itemId,
      'itemType': itemType,
    });
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

  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp();
    Hive.init(dir.path);
    for (final box in [
      'posts',
      'comments',
      'action_queue',
      'post_queue',
      'bookmarks',
      'hashtags',
      'preferences',
      'notifications',
      'notification_queue',
    ]) {
      await Hive.openBox(box);
    }

    Get.testMode = true;
    Get.put<AuthController>(TestAuthController());
    final feedService = DummyFeedService();
    Get.put<FeedController>(FeedController(service: feedService));
    final mentionService = RecordingMentionService(
      databases: Databases(Client()),
      notificationService: RecordingNotificationService(),
      databaseId: 'db',
      profilesCollectionId: 'profiles',
    );
    Get.put<MentionService>(mentionService);
  });

  tearDown(() async {
    Get.reset();
    await Hive.deleteFromDisk();
    await dir.delete(recursive: true);
  });

  testWidgets('mention notifications sent on edit', (tester) async {
    final controller = Get.find<FeedController>();
    final post = FeedPost(
      id: 'p1',
      roomId: 'r1',
      userId: 'u1',
      username: 'tester',
      content: 'old',
      createdAt: DateTime.now(),
    );
    controller.posts.add(post);

    await tester.pumpWidget(
      GetMaterialApp(
        theme: MD3ThemeSystem.createTheme(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        home: EditPostPage(post: post),
      ),
    );

    await tester.pump();

    await tester.enterText(find.byType(TextField), 'update @bob');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final mentionService = Get.find<MentionService>() as RecordingMentionService;
    expect(mentionService.calls.length, 1);
    expect(mentionService.calls.first['itemId'], post.id);
    expect(mentionService.calls.first['mentions'], ['bob']);
    expect(mentionService.calls.first['itemType'], 'post');
  });
}

