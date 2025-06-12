import 'package:flutter/material.dart';
import '../../../design_system/modern_ui_system.dart';
import '../models/post_comment.dart';

class CommentCard extends StatelessWidget {
  final PostComment comment;
  const CommentCard({super.key, required this.comment});

  @override
  Widget build(BuildContext context) {
    return GlassmorphicCard(
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
        ],
      ),
    );
  }
}
