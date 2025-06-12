import 'package:get/get.dart';
import '../models/post_comment.dart';
import '../services/feed_service.dart';

class CommentsController extends GetxController {
  final FeedService service;

  CommentsController({required this.service});

  final _comments = <PostComment>[].obs;
  List<PostComment> get comments => _comments;

  final _isLoading = false.obs;
  bool get isLoading => _isLoading.value;

  Future<void> loadComments(String postId) async {
    _isLoading.value = true;
    try {
      final data = await service.getComments(postId);
      _comments.assignAll(data);
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> addComment(PostComment comment) async {
    await service.createComment(comment);
    _comments.add(comment);
  }
}
