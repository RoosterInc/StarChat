import 'package:flutter/material.dart';
import '../../../design_system/modern_ui_system.dart';
import '../models/feed_post.dart';

class PostCard extends StatelessWidget {
  final FeedPost post;
  const PostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return GlassmorphicCard(
      padding: DesignTokens.md(context).all,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            post.username,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(height: DesignTokens.sm(context)),
          Text(post.content),
        ],
      ),
    );
  }
}
