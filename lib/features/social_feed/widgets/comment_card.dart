import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../design_system/modern_ui_system.dart';
import '../models/post_comment.dart';
import '../controllers/comments_controller.dart';
import '../screens/comment_thread_page.dart';
import 'reaction_bar.dart';
import '../../../controllers/auth_controller.dart';

class CommentCard extends StatelessWidget {
  final PostComment comment;
  const CommentCard({super.key, required this.comment});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CommentsController>();
    final auth = Get.find<AuthController>();
    void handleLike() => controller.toggleLikeComment(comment.id);
    void handleReply() {
      final thread = controller.comments
          .where((c) => c.id == comment.id || c.parentId == comment.id)
          .toList();
      Get.to(() => CommentThreadPage(thread: thread));
    }

    Future<void> handleDelete() async {
      final confirm = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Delete Comment?'),
          content: const Text('This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
      if (confirm == true) {
        await controller.deleteComment(comment.id);
      }
    }

    return Obx(
      () => GlassmorphicCard(
        padding: DesignTokens.sm(context).all,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  comment.username,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const Spacer(),
                if (auth.userId == comment.userId)
                  AccessibilityWrapper(
                    semanticLabel: 'Delete comment',
                    isButton: true,
                    child: AnimatedButton(
                      onPressed: handleDelete,
                      child: const Text('Delete'),
                    ),
                  ),
              ],
            ),
            SizedBox(height: DesignTokens.xs(context)),
            Text(comment.content),
            SizedBox(height: DesignTokens.xs(context)),
            ReactionBar(
              onLike: handleLike,
              onComment: handleReply,
              target: ReactionTarget.comment,
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
