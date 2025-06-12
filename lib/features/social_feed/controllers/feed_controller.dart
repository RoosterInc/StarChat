import 'package:get/get.dart';
import '../models/feed_post.dart';
import '../services/feed_service.dart';

class FeedController extends GetxController {
  final FeedService service;

  FeedController({required this.service});

  final _posts = <FeedPost>[].obs;
  List<FeedPost> get posts => _posts;

  final _isLoading = false.obs;
  bool get isLoading => _isLoading.value;

  Future<void> loadPosts(String roomId) async {
    _isLoading.value = true;
    try {
      final data = await service.getPosts(roomId);
      _posts.assignAll(data);
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> createPost(FeedPost post) async {
    await service.createPost(post);
    _posts.insert(0, post);
  }
}
