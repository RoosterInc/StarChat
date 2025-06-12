import 'package:flutter/material.dart';
import '../../../design_system/modern_ui_system.dart';

class ReactionBar extends StatelessWidget {
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onRepost;
  const ReactionBar({super.key, this.onLike, this.onComment, this.onRepost});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AnimatedButton(
          onPressed: onLike,
          child: const Icon(Icons.favorite_border),
        ),
        SizedBox(width: DesignTokens.sm(context)),
        AnimatedButton(
          onPressed: onComment,
          child: const Icon(Icons.mode_comment_outlined),
        ),
        SizedBox(width: DesignTokens.sm(context)),
        AnimatedButton(
          onPressed: onRepost,
          child: const Icon(Icons.repeat),
        ),
      ],
    );
  }
}
