import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../design_system/modern_ui_system.dart';
import '../models/post_comment.dart';
import '../controllers/comments_controller.dart';
import 'comment_card.dart';

class CommentThread extends StatelessWidget {
  final PostComment comment;
  final int depth;

  const CommentThread({
    super.key,
    required this.comment,
    this.depth = 0,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CommentsController>();
    final replies = controller.getReplies(comment.id);
    final canNest = depth < CommentsController.maxDepth;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CommentCard(comment: comment),
        if (canNest && replies.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(left: DesignTokens.sm(context)),
            child: Column(
              children: replies
                  .map(
                    (reply) => CommentThread(
                      comment: reply,
                      depth: depth + 1,
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }
}
