import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:appwrite/appwrite.dart';

import 'package:myapp/features/social_feed/services/feed_service.dart';
import 'package:myapp/features/social_feed/services/mention_service.dart';
import 'package:myapp/features/social_feed/models/feed_post.dart';
import 'package:myapp/features/notifications/services/notification_service.dart';
import 'package:myapp/controllers/auth_controller.dart';

class _OfflineDatabases extends Databases {
  _OfflineDatabases() : super(Client());

  @override
  Future<Document> createDocument({
    required String databaseId,
    required String collectionId,
    required String documentId,
    required Map<dynamic, dynamic> data,
    List<String>? permissions,
  }) async {
    return Future.error('offline');
  }
}

class _FakeDatabases extends Databases {
  _FakeDatabases() : super(Client());

  @override
  Future<Document> createDocument({
    required String databaseId,
    required String collectionId,
    required String documentId,
    required Map<dynamic, dynamic> data,
    List<String>? permissions,
  }) async {
    return Document.fromMap({'\$id': documentId, ...data});
  }
}

class _RecordingMentionService extends MentionService {
  final List<List<String>> calls = [];

  _RecordingMentionService()
      : super(
          databases: Databases(Client()),
          notificationService: NotificationService(
            databases: Databases(Client()),
            databaseId: 'db',
            collectionId: 'n',
            connectivity: Connectivity(),
          ),
          databaseId: 'db',
          profilesCollectionId: 'profiles',
        );

  @override
  Future<void> notifyMentions(
    List<String> mentions,
    String itemId,
    String itemType,
  ) async {
    calls.add(mentions);
  }
}

class FakeAuthController extends AuthController {
  FakeAuthController() {
    account = Account(client);
    databases = Databases(client);
    storage = Storage(client);
    userId = 'actor';
  }

  @override
  void onInit() {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory dir;
  late FeedService offline;

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
      'preferences'
    ]) {
      await Hive.openBox(box);
    }
    offline = FeedService(
      databases: _OfflineDatabases(),
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
      validateReactionFunctionId: 'validate',
    );
    Get.testMode = true;
    Get.put<AuthController>(FakeAuthController());
  });

  tearDown(() async {
    Get.reset();
    await Hive.deleteFromDisk();
    await dir.delete(recursive: true);
  });

  test('mentions notified for queued posts on sync', () async {
    final post = FeedPost(
      id: 'tmp',
      roomId: 'r1',
      userId: 'u',
      username: 'name',
      content: 'hi',
      mentions: ['bob'],
      createdAt: DateTime.now(),
    );

    await offline.createPost(post);

    final mention = _RecordingMentionService();
    Get.put<MentionService>(mention);

    final online = FeedService(
      databases: _FakeDatabases(),
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
      validateReactionFunctionId: 'validate',
    );

    await online.syncQueuedActions();

    expect(mention.calls.isNotEmpty, isTrue);
    expect(mention.calls.first, ['bob']);
  });
}

