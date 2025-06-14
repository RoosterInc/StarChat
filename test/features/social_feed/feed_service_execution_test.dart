import 'dart:io';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:myapp/features/social_feed/models/post_comment.dart';
import 'package:myapp/features/social_feed/services/feed_service.dart';

class _MockDatabases extends Databases {
  _MockDatabases() : super(Client());

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
      '\$createdAt': DateTime.now().toIso8601String(),
      '\$updatedAt': DateTime.now().toIso8601String(),
      '\$permissions': [],
      ...data,
    });
  }
}

class _MockFunctions extends Functions {
  _MockFunctions() : super(Client());

  int executions = 0;
  String? lastId;
  Map<String, dynamic>? lastPayload;

  @override
  Future<Execution> createExecution({
    required String functionId,
    String? body,
    String? xrea,
    bool? async,
  }) async {
    executions++;
    lastId = functionId;
    lastPayload = body == null ? null : jsonDecode(body);
    return Execution.fromMap({
      '\$id': 'e1',
      '\$createdAt': DateTime.now().toIso8601String(),
      '\$updatedAt': DateTime.now().toIso8601String(),
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

void main() {
  late Directory dir;
  late FeedService service;
  late _MockFunctions functions;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp();
    Hive.init(dir.path);
    await Hive.openBox('posts');
    await Hive.openBox('comments');
    await Hive.openBox('action_queue');
    await Hive.openBox('post_queue');
    await Hive.openBox('bookmarks');
    functions = _MockFunctions();
    service = FeedService(
      databases: _MockDatabases(),
      storage: Storage(Client()),
      functions: functions,
      databaseId: 'db',
      postsCollectionId: 'posts',
      commentsCollectionId: 'comments',
      likesCollectionId: 'likes',
      repostsCollectionId: 'reposts',
      bookmarksCollectionId: 'bookmarks',
      connectivity: Connectivity(),
      linkMetadataFunctionId: 'fetch_link_metadata',
    );
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await dir.delete(recursive: true);
  });

  test('createComment triggers increment function', () async {
    final comment = PostComment(
      id: '1',
      postId: 'p1',
      userId: 'u',
      username: 'name',
      content: 'hi',
    );
    await service.createComment(comment);
    expect(functions.executions, 1);
    expect(functions.lastId, 'increment_comment_count');
    expect(functions.lastPayload, {'post_id': 'p1'});
  });

  test('createLike triggers increment function', () async {
    await service.createLike({'item_id': 'p1', 'item_type': 'post', 'user_id': 'u'});
    expect(functions.executions, 1);
    expect(functions.lastId, 'increment_like_count');
    expect(functions.lastPayload, {'item_id': 'p1', 'item_type': 'post'});
  });
}
