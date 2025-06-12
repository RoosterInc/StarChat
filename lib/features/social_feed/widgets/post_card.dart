import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../design_system/modern_ui_system.dart';
import '../models/feed_post.dart';
import '../controllers/feed_controller.dart';
import '../screens/post_detail_page.dart';
import 'media_gallery.dart';
import 'reaction_bar.dart';

class PostCard extends StatefulWidget {
  final FeedPost post;
  const PostCard({super.key, required this.post});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool isLiked = false;

  void _handleLike() {
    final controller = Get.find<FeedController>();
    controller.likePost(widget.post.id);
    setState(() => isLiked = !isLiked);
  }

  void _handleComment() {
    Get.to(() => PostDetailPage(post: widget.post));
  }

  void _handleRepost() {
    final controller = Get.find<FeedController>();
    controller.repostPost(widget.post.id);
  }

  @override
  Widget build(BuildContext context) {
    return GlassmorphicCard(
      padding: DesignTokens.md(context).all,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.post.username,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(height: DesignTokens.sm(context)),
          Text(widget.post.content),
          if (widget.post.mediaUrls.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: DesignTokens.sm(context)),
              child: MediaGallery(urls: widget.post.mediaUrls),
            ),
          SizedBox(height: DesignTokens.sm(context)),
          ReactionBar(
            onLike: _handleLike,
            onComment: _handleComment,
            onRepost: _handleRepost,
            isLiked: isLiked,
          ),
        ],
      ),
    );
  }
}
