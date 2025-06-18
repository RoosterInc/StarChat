import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/design_system/modern_ui_system.dart';
import '../models/post_comment.dart';
import '../controllers/comments_controller.dart';
import '../screens/comment_thread_page.dart';
import 'reaction_bar.dart';
import '../../authentication/controllers/auth_controller.dart';
import 'package:flutter/gestures.dart';
import '../../profile/screens/profile_page.dart';
import '../../../bindings/profile_binding.dart';
import '../../profile/services/profile_service.dart';

class CommentCard extends StatelessWidget {
  final PostComment comment;
  const CommentCard({super.key, required this.comment});

  Widget _buildContent(BuildContext context) {
    final spans = <TextSpan>[];
    final words = comment.content.split(RegExp(r'(\s+)'));
    for (final word in words) {
      if (word.startsWith('@')) {
        final name =
            word.substring(1).replaceAll(RegExp(r'[!?,.:;]+$'), '');
        spans.add(TextSpan(
          text: '$word ',
          style: TextStyle(color: Theme.of(context).colorScheme.primary),
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              _openProfile(name);
            },
        ));
      } else {
        spans.add(TextSpan(text: '$word '));
      }
    }
    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.bodyMedium,
        children: spans,
      ),
    );
  }

  Future<void> _openProfile(String username) async {
    final id = await Get.find<ProfileService>()
        .getUserIdByUsername(username);
    if (id != null) {
      Get.to(
        () => UserProfilePage(userId: id),
        binding: ProfileBinding(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CommentsController>();
    final auth = Get.find<AuthController>();
    void handleLike() => controller.toggleLikeComment(comment.id);
    void handleReply() {
      Get.to(() => CommentThreadPage(rootComment: comment));
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
        try {
          await controller.deleteComment(comment.id);
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('failed_to_delete_comment'.tr),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
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
            _buildContent(context),
            SizedBox(height: DesignTokens.xs(context)),
            ReactionBar(
              onLike: handleLike,
              onComment: handleReply,
              target: ReactionTarget.comment,
              isLiked: controller.isCommentLiked(comment.id),
              likeCount: controller.commentLikeCount(comment.id),
              commentCount: controller.commentReplyCount(comment.id),
              repostCount: 0,
            ),
          ],
        ),
      ),
    );
  }
}
