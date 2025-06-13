import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:myapp/features/bookmarks/controllers/bookmark_controller.dart';
import 'package:myapp/features/bookmarks/screens/bookmark_list_page.dart';
import 'package:myapp/features/social_feed/services/feed_service.dart';
import 'package:appwrite/appwrite.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../test_utils/fake_connectivity.dart';
import 'package:myapp/features/bookmarks/models/bookmark.dart';

void main() {
  testWidgets('renders bookmark list page', (tester) async {
    Get.put(BookmarkController(service: FakeService()));
    await tester.pumpWidget(const GetMaterialApp(home: BookmarkListPage()));
    expect(find.text('Bookmarks'), findsOneWidget);
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
          connectivity: FakeConnectivity(),
          linkMetadataFunctionId: 'link',
        );

  @override
  Future<List<BookmarkedPost>> listBookmarks(String userId) async => [];
}
