import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;

import 'package:myapp/features/social_feed/widgets/post_card.dart';
import 'package:myapp/features/social_feed/models/feed_post.dart';
import 'package:myapp/features/bookmarks/controllers/bookmark_controller.dart';
import 'package:myapp/features/social_feed/controllers/feed_controller.dart';
import 'package:myapp/controllers/auth_controller.dart';

class RecordingDatabases extends Databases {
  RecordingDatabases() : super(Client());
  List<String>? queries;
  @override
  Future<models.DocumentList> listDocuments({
    required String databaseId,
    required String collectionId,
    List<String>? queries,
  }) async {
    this.queries = queries;
    return models.DocumentList(total: 1, documents: [
      models.Document.fromMap({
        '\$id': 'uid',
        '\$collectionId': collectionId,
        '\$databaseId': databaseId,
        '\$createdAt': '',
        '\$updatedAt': '',
        '\$permissions': [],
        'username': 'alice',
      })
    ]);
  }
}

class TestAuthController extends AuthController {
  TestAuthController(this.db) {
    account = Account(client);
    databases = db;
    storage = Storage(client);
    userId = 'u1';
    username.value = 'tester';
  }
  final Databases db;
  @override
  Future<void> checkExistingSession({bool navigateOnMissing = true}) async {}
}

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
          bookmarksCollectionId: 'bookmarks',
          connectivity: Connectivity(),
          linkMetadataFunctionId: 'fetch_link_metadata',
        );

  @override
  Future<List<FeedPost>> getPosts(String roomId, {List<String> blockedIds = const []}) async => [];

  @override
  Future<PostLike?> getUserLike(String itemId, String userId) async => null;

  @override
  Future<String?> createRepost(Map<String, dynamic> repost) async => 'r1';

  @override
  Future<void> deleteRepost(String repostId, String postId) async {}

  @override
  Future<PostRepost?> getUserRepost(String postId, String userId) async => null;

  @override
  Future<void> createLike(Map<String, dynamic> like) async {}

  @override
  Future<void> deleteLike(String likeId, {required String itemId, required String itemType}) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RecordingDatabases db;

  setUp(() {
    Get.testMode = true;
    db = RecordingDatabases();
    Get.put<AuthController>(TestAuthController(db));
    final service = FakeFeedService();
    Get.put<FeedController>(FeedController(service: service));
    Get.put<BookmarkController>(BookmarkController(service: service));
  });

  tearDown(Get.reset);

  testWidgets('mentions with punctuation open profile', (tester) async {
    final post = FeedPost(
      id: 'p1',
      roomId: 'r1',
      userId: 'u1',
      username: 'tester',
      content: 'hello @alice, welcome',
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(GetMaterialApp(home: PostCard(post: post)));
    await tester.tap(find.textContaining('@alice,'));
    await tester.pump();

    expect(db.queries?.first.contains('alice'), isTrue);
  });
}

