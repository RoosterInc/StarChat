import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../design_system/modern_ui_system.dart';
import '../controllers/comments_controller.dart';
import '../models/feed_post.dart';
import '../widgets/comment_card.dart';
import '../widgets/post_card.dart';

class PostDetailPage extends StatelessWidget {
  final FeedPost post;
  const PostDetailPage({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CommentsController>();
    controller.loadComments(post.id);
    return Scaffold(
      appBar: AppBar(title: const Text('Post')),
      body: OptimizedListView(
        padding: EdgeInsets.all(DesignTokens.md(context)),
        itemCount: controller.comments.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) return PostCard(post: post);
          final comment = controller.comments[index - 1];
          return Padding(
            padding: EdgeInsets.only(top: DesignTokens.sm(context)),
            child: CommentCard(comment: comment),
          );
        },
      ),
    );
  }
}
