import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../design_system/modern_ui_system.dart';
import '../models/post_comment.dart';
import '../controllers/comments_controller.dart';
import '../screens/comment_thread_page.dart';
import 'reaction_bar.dart';

class CommentCard extends StatelessWidget {
  final PostComment comment;
  const CommentCard({super.key, required this.comment});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CommentsController>();
    void handleLike() => controller.toggleLikeComment(comment.id);
    void handleReply() {
      final thread = controller.comments
          .where((c) => c.id == comment.id || c.parentId == comment.id)
          .toList();
      Get.to(() => CommentThreadPage(thread: thread));
    }

    return Obx(
      () => GlassmorphicCard(
        padding: DesignTokens.sm(context).all,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              comment.username,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(height: DesignTokens.xs(context)),
            Text(comment.content),
            SizedBox(height: DesignTokens.xs(context)),
            ReactionBar(
              onLike: handleLike,
              onComment: handleReply,
              isLiked: controller.isCommentLiked(comment.id),
              likeCount: controller.commentLikeCount(comment.id),
              commentCount: comment.replyCount,
              repostCount: 0,
            ),
          ],
        ),
      ),
    );
  }
}
