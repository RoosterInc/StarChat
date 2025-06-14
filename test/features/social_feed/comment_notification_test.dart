import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:myapp/features/social_feed/services/feed_service.dart';
import 'package:myapp/features/social_feed/models/post_comment.dart';
import 'package:myapp/features/notifications/services/notification_service.dart';

class RecordingNotificationService extends NotificationService {
  int count = 0;
  Map<String, dynamic>? last;
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
    last = {
      'userId': userId,
      'actorId': actorId,
      'actionType': actionType,
      'itemId': itemId,
      'itemType': itemType,
    };
  }
}

class FakeDatabases extends Databases {
  bool failCreate = false;
  FakeDatabases() : super(Client());

  @override
  Future<models.Document> createDocument({
    required String databaseId,
    required String collectionId,
    required String documentId,
    required Map<dynamic, dynamic> data,
    List<String>? permissions,
  }) async {
    if (failCreate) return Future.error('offline');
    return models.Document.fromMap({
      ...data,
      '\$id': documentId,
      '\$collectionId': collectionId,
      '\$databaseId': databaseId,
      '\$createdAt': '',
      '\$updatedAt': '',
      '\$permissions': [],
    });
  }

  @override
  Future<models.Document> getDocument({
    required String databaseId,
    required String collectionId,
    required String documentId,
  }) async {
    final userId = collectionId == 'posts' ? 'post_owner' : 'comment_owner';
    return models.Document.fromMap({
      '\$id': documentId,
      '\$collectionId': collectionId,
      '\$databaseId': databaseId,
      '\$createdAt': '',
      '\$updatedAt': '',
      '\$permissions': [],
      'user_id': userId,
    });
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  late FeedService service;
  late RecordingNotificationService notification;
  late FakeDatabases db;

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
      'notifications',
      'notification_queue'
    ]) {
      await Hive.openBox(box);
    }
    db = FakeDatabases();
    notification = RecordingNotificationService();
    Get.put<NotificationService>(notification);
    service = FeedService(
      databases: db,
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
  });

  tearDown(() async {
    Get.reset();
    await Hive.deleteFromDisk();
    await dir.delete(recursive: true);
  });

  test('createComment notifies post owner on top-level comment', () async {
    final c = PostComment(
      id: '1',
      postId: 'p1',
      userId: 'actor',
      username: 'bob',
      content: 'hi',
    );

    await service.createComment(c);

    expect(notification.count, 1);
    expect(notification.last?['userId'], 'post_owner');
    expect(notification.last?['actionType'], 'comment');
    expect(notification.last?['itemId'], 'p1');
    expect(notification.last?['itemType'], 'post');
  });

  test('createComment notifies parent owner on reply', () async {
    final c = PostComment(
      id: '2',
      postId: 'p1',
      userId: 'actor',
      username: 'bob',
      parentId: 'parent',
      content: 'hi',
    );

    await service.createComment(c);

    expect(notification.count, 1);
    expect(notification.last?['userId'], 'comment_owner');
    expect(notification.last?['actionType'], 'reply');
    expect(notification.last?['itemId'], 'parent');
    expect(notification.last?['itemType'], 'comment');
  });

  test('offline createComment queues and skips notification', () async {
    db.failCreate = true;
    final c = PostComment(
      id: '3',
      postId: 'p1',
      userId: 'actor',
      username: 'bob',
      content: 'hi',
    );

    await service.createComment(c);

    expect(Hive.box('action_queue').isNotEmpty, isTrue);
    expect(notification.count, 0);
  });
}

