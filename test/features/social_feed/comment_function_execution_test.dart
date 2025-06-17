import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:myapp/features/social_feed/services/feed_service.dart';
import 'package:myapp/features/social_feed/models/post_comment.dart';


class FakeDatabases extends Databases {
  FakeDatabases() : super(Client());
  final List<Map<String, dynamic>> updates = [];
  final Map<String, Map<String, dynamic>> docs = {};

  @override
  Future<Document> createDocument({
    required String databaseId,
    required String collectionId,
    required String documentId,
    required Map<dynamic, dynamic> data,
    List<String>? permissions,
  }) async {
    docs[documentId] = Map<String, dynamic>.from(data);
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
  Future<Document> getDocument({
    required String databaseId,
    required String collectionId,
    required String documentId,
    List<String>? queries,
  }) async {
    final data = docs[documentId] ?? {};
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
    updates.add({
      'collectionId': collectionId,
      'documentId': documentId,
      'data': data,
    });
    final existing = docs[documentId] ?? {};
    docs[documentId] = {
      ...existing,
      ...?data,
    };
    return Document.fromMap({
      '\$id': documentId,
      '\$collectionId': collectionId,
      '\$databaseId': databaseId,
      '\$createdAt': '',
      '\$updatedAt': '',
      '\$permissions': [],
      ...docs[documentId]!,
    });
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory dir;
  late FeedService service;
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
      'preferences'
    ]) {
      await Hive.openBox(box);
    }
    db = FakeDatabases();
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
    expect(db.updates.last['collectionId'], 'posts');
    expect(db.updates.last['data'], {'comment_count': 1});
    final cached = Hive.box('posts').get('k') as List;
    expect(cached.first['comment_count'], 1);
  });

  test('create reply triggers both comment and reply functions', () async {
    Hive.box('posts').put('k', [
      {'id': 'p1', 'comment_count': 0}
    ]);
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
    expect(db.updates.length, 2);
    expect(db.updates.first['collectionId'], 'posts');
    expect(db.updates.first['data'], {'comment_count': 1});
    expect(db.updates.last['collectionId'], 'comments');
    expect(db.updates.last['data'], {'reply_count': 1});
    final cachedComments = Hive.box('comments').get('c_post') as List;
    expect(cachedComments.first['reply_count'], 1);
    final cachedPosts = Hive.box('posts').get('k') as List;
    expect(cachedPosts.first['comment_count'], 1);
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
    expect(db.updates.last['collectionId'], 'posts');
    expect(db.updates.last['data'], {'comment_count': -1});
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
    expect(db.updates.last['collectionId'], 'comments');
    expect(db.updates.last['data'], {'reply_count': -1});
    final cached = Hive.box('comments').get('c_post') as List;
    expect(cached.first['reply_count'], 0);
  });
}
