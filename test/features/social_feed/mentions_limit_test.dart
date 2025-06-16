import 'package:flutter_test/flutter_test.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

import 'package:myapp/features/social_feed/services/feed_service.dart';
import 'package:myapp/features/social_feed/models/feed_post.dart';
import 'package:myapp/features/social_feed/services/mention_service.dart';
import 'package:myapp/features/notifications/services/notification_service.dart';
import 'package:myapp/controllers/auth_controller.dart';

class RecordingFeedService extends FeedService {
  RecordingFeedService()
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

  final List<FeedPost> store = [];

  @override
  Future<String?> createPost(FeedPost post) async {
    store.add(post);
    return post.id;
  }
}

class FakeDatabases extends Databases {
  FakeDatabases() : super(Client());

  List<String> _parseNames(String query) {
    final start = query.indexOf('[');
    if (start != -1) {
      final end = query.indexOf(']', start);
      final inside =
          query.substring(start + 1, end).replaceAll('"', '').trim();
      if (inside.isEmpty) return [];
      return inside.split(',').map((e) => e.trim()).toList();
    }
    final match = RegExp(r'"([^"]+)"').firstMatch(query);
    return match != null ? [match.group(1)!] : [];
  }

  @override
  Future<models.DocumentList> listDocuments({
    required String databaseId,
    required String collectionId,
    List<String>? queries,
  }) async {
    final query = queries?.first ?? '';
    final names = _parseNames(query);
    final docs = names
        .map((n) => models.Document.fromMap({
              '\$id': n,
              '\$collectionId': collectionId,
              '\$databaseId': databaseId,
              '\$createdAt': '',
              '\$updatedAt': '',
              '\$permissions': [],
              'username': n,
            }))
        .toList();
    return models.DocumentList(total: docs.length, documents: docs);
  }
}

class RecordingNotificationService extends NotificationService {
  int count = 0;
  RecordingNotificationService()
      : super(
          databases: Databases(Client()),
          databaseId: 'db',
          collectionId: 'notifications',
          connectivity: Connectivity(),
        );
  @override
  Future<void> createNotification(
    String userId,
    String actorId,
    String actionType, {
    String? itemId,
    String? itemType,
  }) async {
    count++;
  }
}

class FakeAuthController extends AuthController {
  FakeAuthController() {
    account = Account(client);
    databases = FakeDatabases();
    storage = Storage(client);
    userId = 'actor';
  }

  @override
  void onInit() {}
}


void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.testMode = true;
    Get.put<AuthController>(FakeAuthController());
    Get.put<NotificationService>(RecordingNotificationService());
  });

  tearDown(() {
    Get.reset();
  });

  test('post stores and notifies only first 10 mentions', () async {
    final service = RecordingFeedService();
    final mentions = List.generate(12, (i) => 'user$i');
    final post = FeedPost(
      id: 'p1',
      roomId: 'room',
      userId: 'actor',
      username: 'actor',
      content: 'hi',
      mentions: mentions,
      createdAt: DateTime.now(),
    );
    await service.createPost(post);

    expect(service.store.first.mentions.length, 10);

    final mentionService = MentionService(
      databases: Get.find<AuthController>().databases,
      notificationService: Get.find<NotificationService>(),
      databaseId: 'db',
      profilesCollectionId: 'profiles',
    );

    await mentionService.notifyMentions(
      service.store.first.mentions,
      'p1',
      'post',
    );

    final recorder =
        Get.find<NotificationService>() as RecordingNotificationService;
    expect(recorder.count, 10);
  });
}
