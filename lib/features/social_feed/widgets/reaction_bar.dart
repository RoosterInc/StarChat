import 'package:flutter/material.dart';
import '../../../design_system/modern_ui_system.dart';

class ReactionBar extends StatelessWidget {
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onRepost;
  final bool isLiked;
  final int likeCount;
  final int commentCount;
  final int repostCount;
  const ReactionBar({
    super.key,
    this.onLike,
    this.onComment,
    this.onRepost,
    this.isLiked = false,
    this.likeCount = 0,
    this.commentCount = 0,
    this.repostCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    Widget buildItem({
      required Widget icon,
      required String label,
      required VoidCallback? onTap,
      required int count,
    }) {
      return AccessibilityWrapper(
        semanticLabel: label,
        isButton: true,
        child: AnimatedButton(
          onPressed: onTap,
          child: Row(
            children: [
              icon,
              SizedBox(width: DesignTokens.xs(context)),
              Text('$count'),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        buildItem(
          icon: Icon(
            isLiked ? Icons.favorite : Icons.favorite_border,
            color: isLiked
                ? context.colorScheme.primary
                : context.theme.iconTheme.color,
          ),
          label: isLiked ? 'Unlike post' : 'Like post',
          onTap: onLike,
          count: likeCount,
        ),
        SizedBox(width: DesignTokens.sm(context)),
        buildItem(
          icon: const Icon(Icons.mode_comment_outlined),
          label: 'Comment on post',
          onTap: onComment,
          count: commentCount,
        ),
        SizedBox(width: DesignTokens.sm(context)),
        buildItem(
          icon: const Icon(Icons.repeat),
          label: 'Repost',
          onTap: onRepost,
          count: repostCount,
        ),
      ],
    );
  }
}
