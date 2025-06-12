import 'package:flutter_test/flutter_test.dart';
import 'package:appwrite/appwrite.dart';
import 'package:myapp/features/social_feed/controllers/feed_controller.dart';
import 'package:myapp/features/social_feed/models/feed_post.dart';
import 'package:myapp/features/social_feed/services/feed_service.dart';

class FakeFeedService extends FeedService {
  FakeFeedService()
      : super(
          databases: Databases(Client()),
          databaseId: 'db',
          postsCollectionId: 'posts',
          commentsCollectionId: 'comments',
        );

  final List<FeedPost> _store = [];

  @override
  Future<List<FeedPost>> getPosts(String roomId) async {
    return _store.where((p) => p.roomId == roomId).toList();
  }

  @override
  Future<void> createPost(FeedPost post) async {
    _store.add(post);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loadPosts returns empty list', () async {
    final service = FakeFeedService();
    final controller = FeedController(service: service);
    await controller.loadPosts('room');
    expect(controller.posts, isEmpty);
  }, skip: true);

  test('createPost adds to list', () async {
    final service = FakeFeedService();
    final controller = FeedController(service: service);
    final post = FeedPost(
      id: '1',
      roomId: 'room',
      userId: 'u1',
      username: 'user',
      content: 'hello',
    );
    await controller.createPost(post);
    expect(controller.posts.length, 1);
  }, skip: true);
}
