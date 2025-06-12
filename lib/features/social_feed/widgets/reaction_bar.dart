import 'package:flutter/material.dart';
import '../../../design_system/modern_ui_system.dart';

class ReactionBar extends StatelessWidget {
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onRepost;
  final bool isLiked;
  const ReactionBar({
    super.key,
    this.onLike,
    this.onComment,
    this.onRepost,
    this.isLiked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AccessibilityWrapper(
          semanticLabel: isLiked ? 'Unlike post' : 'Like post',
          isButton: true,
          child: AnimatedButton(
            onPressed: onLike,
            child: Icon(
              isLiked ? Icons.favorite : Icons.favorite_border,
              color: isLiked
                  ? context.colorScheme.primary
                  : context.theme.iconTheme.color,
            ),
          ),
        ),
        SizedBox(width: DesignTokens.sm(context)),
        AccessibilityWrapper(
          semanticLabel: 'Comment on post',
          isButton: true,
          child: AnimatedButton(
            onPressed: onComment,
            child: const Icon(Icons.mode_comment_outlined),
          ),
        ),
        SizedBox(width: DesignTokens.sm(context)),
        AccessibilityWrapper(
          semanticLabel: 'Repost',
          isButton: true,
          child: AnimatedButton(
            onPressed: onRepost,
            child: const Icon(Icons.repeat),
          ),
        ),
      ],
    );
  }
}
