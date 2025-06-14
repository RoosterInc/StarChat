import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:myapp/features/bookmarks/controllers/bookmark_controller.dart';
import 'package:myapp/features/bookmarks/screens/bookmark_list_page.dart';
import 'package:myapp/features/social_feed/services/feed_service.dart';
import 'package:myapp/features/social_feed/models/feed_post.dart';
import 'package:myapp/features/social_feed/controllers/feed_controller.dart';
import 'package:myapp/features/social_feed/widgets/post_card.dart';
import 'package:myapp/controllers/auth_controller.dart';
import 'package:myapp/design_system/modern_ui_system.dart';
import 'package:appwrite/appwrite.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:myapp/features/bookmarks/models/bookmark.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.testMode = true;
  });

  testWidgets('renders bookmark list page', (tester) async {
    Get.put(BookmarkController(service: FakeService()));
    await tester.pumpWidget(const GetMaterialApp(home: BookmarkListPage()));
    expect(find.text('Bookmarks'), findsOneWidget);
  });

  testWidgets('displays bookmarks using OptimizedListView', (tester) async {
    final dir = await Directory.systemTemp.createTemp();
    Hive.init(dir.path);
    await Hive.openBox('posts');
    await Hive.openBox('comments');
    await Hive.openBox('action_queue');
    await Hive.openBox('post_queue');
    await Hive.openBox('bookmarks');
    await Hive.openBox('hashtags');
    await Hive.openBox('preferences');

    final post = FeedPost(
      id: '1',
      roomId: 'r',
      userId: 'u',
      username: 'user',
      content: 'content',
    );
    final bookmark = BookmarkedPost(
      bookmark: Bookmark(
        id: 'b1',
        postId: '1',
        userId: 'u',
        createdAt: DateTime.now(),
      ),
      post: post,
    );

    final service = DataService([bookmark]);
    Get.put<FeedController>(FeedController(service: service));
    Get.put<BookmarkController>(BookmarkController(service: service));
    Get.put<AuthController>(_FakeAuthController('u'));

    await tester.pumpWidget(const GetMaterialApp(home: BookmarkListPage()));
    await tester.pump();

    expect(find.byType(OptimizedListView), findsOneWidget);
    expect(find.byType(PostCard), findsOneWidget);

    await Hive.deleteFromDisk();
    await dir.delete(recursive: true);
    Get.reset();
  });
}

class FakeService extends FeedService {
  FakeService()
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

  @override
  Future<List<BookmarkedPost>> listBookmarks(String userId) async => [];
}

class DataService extends FakeService {
  final List<BookmarkedPost> items;
  DataService(this.items);

  @override
  Future<List<BookmarkedPost>> listBookmarks(String userId) async => items;
}

class _FakeAuthController extends AuthController {
  _FakeAuthController(String id) {
    userId = id;
    account = Account(client);
    databases = Databases(client);
    storage = Storage(client);
  }

  @override
  Future<void> checkExistingSession({bool navigateOnMissing = true}) async {}
}
