import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:appwrite/appwrite.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:myapp/features/social_feed/screens/compose_post_page.dart';
import 'package:myapp/features/social_feed/controllers/feed_controller.dart';
import 'package:myapp/features/social_feed/models/feed_post.dart';
import 'package:myapp/features/social_feed/services/feed_service.dart';
import 'package:myapp/features/social_feed/services/mention_service.dart';
import 'package:myapp/features/notifications/services/notification_service.dart';
import 'package:myapp/controllers/auth_controller.dart';
import 'package:myapp/design_system/modern_ui_system.dart';

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

  final List<FeedPost> posts = [];

  @override
  Future<String?> createPost(FeedPost post) async {
    posts.add(post);
    return post.id;
  }

  @override
  Future<void> saveHashtags(List<String> tags) async {}
}

class RecordingMentionService extends MentionService {
  RecordingMentionService({required super.databases, required super.notificationService, required super.databaseId, required super.profilesCollectionId});

  final List<Map<String, dynamic>> calls = [];

  @override
  Future<void> notifyMentions(List<String> mentions, String itemId, String itemType) async {
    calls.add({'mentions': mentions, 'itemId': itemId, 'itemType': itemType});
  }
}

class DummyNotificationService extends NotificationService {
  DummyNotificationService()
      : super(
          databases: Databases(Client()),
          databaseId: 'db',
          collectionId: 'col',
          connectivity: Connectivity(),
        );

  @override
  Future<void> createNotification(String userId, String actorId, String actionType, {String? itemId, String? itemType}) async {}
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

  setUp(() {
    Get.testMode = true;
    Get.put<AuthController>(TestAuthController());
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('posting truncates mentions to first 10', (tester) async {
    final service = TestFeedService();
    final controller = FeedController(service: service);
    Get.put<FeedController>(controller);

    final mentionService = RecordingMentionService(
      databases: Databases(Client()),
      notificationService: DummyNotificationService(),
      databaseId: 'db',
      profilesCollectionId: 'profiles',
    );
    Get.put<MentionService>(mentionService);
    Get.put<NotificationService>(DummyNotificationService());

    await tester.pumpWidget(
      GetMaterialApp(
        theme: MD3ThemeSystem.createTheme(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        home: const ComposePostPage(roomId: 'r1'),
      ),
    );

    await tester.pump();
    final text = List.generate(12, (i) => '@user$i').join(' ');
    await tester.enterText(find.byType(TextField), text);
    await tester.tap(find.text('Post'));
    await tester.pump();

    expect(service.posts.first.mentions.length, 10);
    final call = mentionService.calls.first;
    expect(call['mentions'].length, 10);
  });
}

