import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:myapp/features/social_feed/services/feed_service.dart';
import 'package:myapp/features/social_feed/models/post_comment.dart';

class RecordingFunctions extends Functions {
  RecordingFunctions() : super(Client());

  String? lastFunctionId;
  String? lastBody;

  @override
  Future<Execution> createExecution({
    required String functionId,
    String? body,
    Map<String, dynamic>? xHeaders,
    String? path,
  }) async {
    lastFunctionId = functionId;
    lastBody = body;
    return Execution.fromMap({
      '\$id': '1',
      '\$createdAt': '',
      '\$updatedAt': '',
      '\$permissions': [],
      'functionId': functionId,
      'trigger': 'http',
      'status': 'completed',
      'requestMethod': 'GET',
      'requestPath': '/',
      'requestHeaders': [],
      'responseStatusCode': 200,
      'responseBody': '',
      'responseHeaders': [],
      'logs': '',
      'errors': '',
      'duration': 0.0,
    });
  }
}

class FakeDatabases extends Databases {
  FakeDatabases() : super(Client());

  @override
  Future<Document> createDocument({
    required String databaseId,
    required String collectionId,
    required String documentId,
    required Map<dynamic, dynamic> data,
    List<String>? permissions,
  }) async {
    return Document.fromMap({
      '\$id': documentId,
      '\$collectionId': collectionId,
      '\$databaseId': databaseId,
      '\$createdAt': '',
      '\$updatedAt': '',
      '\$permissions': [],
      ...data,
    });
  }

  @override
  Future<Document> updateDocument({
    required String databaseId,
    required String collectionId,
    required String documentId,
    Map<dynamic, dynamic>? data,
    List<String>? permissions,
  }) async {
    return Document.fromMap({
      '\$id': documentId,
      '\$collectionId': collectionId,
      '\$databaseId': databaseId,
      '\$createdAt': '',
      '\$updatedAt': '',
      '\$permissions': [],
      ...?data,
    });
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory dir;
  late FeedService service;
  late RecordingFunctions functions;

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
    functions = RecordingFunctions();
    service = FeedService(
      databases: FakeDatabases(),
      storage: Storage(Client()),
      functions: functions,
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
    await Hive.deleteFromDisk();
    await dir.delete(recursive: true);
  });

  test('createComment triggers increment_comment_count', () async {
    Hive.box('posts').put('k', [
      {'id': 'p1', 'comment_count': 0}
    ]);
    final comment = PostComment(
      id: 'c1',
      postId: 'p1',
      userId: 'u',
      username: 'name',
      content: 'hi',
    );
    await service.createComment(comment);
    expect(functions.lastFunctionId, 'increment_comment_count');
    expect(functions.lastBody, '{"post_id":"p1"}');
    final cached = Hive.box('posts').get('k') as List;
    expect(cached.first['comment_count'], 1);
  });

  test('create reply triggers increment_reply_count', () async {
    Hive.box('comments').put('c_post', [
      {'id': 'c1', 'post_id': 'p1', 'reply_count': 0}
    ]);
    final reply = PostComment(
      id: 'c2',
      postId: 'p1',
      parentId: 'c1',
      userId: 'u',
      username: 'name',
      content: 'reply',
    );
    await service.createComment(reply);
    expect(functions.lastFunctionId, 'increment_reply_count');
    expect(functions.lastBody, '{"comment_id":"c1"}');
    final cached = Hive.box('comments').get('c_post') as List;
    expect(cached.first['reply_count'], 1);
  });

  test('deleteComment triggers decrement_comment_count', () async {
    Hive.box('posts').put('k', [
      {'id': 'p1', 'comment_count': 2}
    ]);
    Hive.box('comments').put('c_post', [
      {'id': 'c1', 'post_id': 'p1', 'reply_count': 0, 'is_deleted': false}
    ]);
    final comment = PostComment(
      id: 'c1',
      postId: 'p1',
      userId: 'u',
      username: 'name',
      content: 'hi',
    );
    await service.deleteComment(comment);
    expect(functions.lastFunctionId, 'decrement_comment_count');
    expect(functions.lastBody, '{"post_id":"p1"}');
    final post = Hive.box('posts').get('k') as List;
    expect(post.first['comment_count'], 1);
    final cached = Hive.box('comments').get('c_post') as List;
    expect(cached.first['is_deleted'], true);
  });

  test('delete reply triggers decrement_reply_count', () async {
    Hive.box('comments').put('c_post', [
      {'id': 'c1', 'post_id': 'p1', 'reply_count': 1},
      {'id': 'c2', 'post_id': 'p1', 'parent_id': 'c1', 'is_deleted': false}
    ]);
    final reply = PostComment(
      id: 'c2',
      postId: 'p1',
      parentId: 'c1',
      userId: 'u',
      username: 'name',
      content: 'reply',
    );
    await service.deleteComment(reply);
    expect(functions.lastFunctionId, 'decrement_reply_count');
    expect(functions.lastBody, '{"comment_id":"c1"}');
    final cached = Hive.box('comments').get('c_post') as List;
    expect(cached.first['reply_count'], 0);
  });
}
