import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../design_system/modern_ui_system.dart';
import '../models/feed_post.dart';
import '../controllers/feed_controller.dart';
import '../screens/post_detail_page.dart';
import 'media_gallery.dart';
import 'reaction_bar.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../widgets/safe_network_image.dart';

class PostCard extends StatelessWidget {
  final FeedPost post;
  const PostCard({super.key, required this.post});

  void _handleLike(FeedController controller) {
    controller.toggleLikePost(post.id);
  }

  void _handleComment() {
    Get.to(() => PostDetailPage(post: post));
  }

  void _handleRepost(FeedController controller) {
    controller.repostPost(post.id);
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FeedController>();
    return Obx(
      () => GlassmorphicCard(
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
            if (post.mediaUrls.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: DesignTokens.sm(context)),
                child: MediaGallery(urls: post.mediaUrls),
              ),
            if (post.linkUrl != null && post.linkMetadata != null)
              Padding(
                padding: EdgeInsets.only(top: DesignTokens.sm(context)),
                child: GlassmorphicCard(
                  padding: DesignTokens.sm(context).all,
                  onTap: () {
                    final uri = Uri.parse(post.linkUrl!);
                    launchUrl(uri, mode: LaunchMode.externalApplication);
                  },
                  child: Row(
                    children: [
                      if (post.linkMetadata!['image'] != null)
                        Padding(
                          padding: EdgeInsets.only(right: DesignTokens.sm(context)),
                          child: SafeNetworkImage(
                            imageUrl: post.linkMetadata!['image'] as String?,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post.linkMetadata!['title'] ?? post.linkUrl!,
                              style: Theme.of(context).textTheme.bodyMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (post.linkMetadata!['description'] != null)
                              Text(
                                post.linkMetadata!['description'],
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            SizedBox(height: DesignTokens.sm(context)),
            ReactionBar(
              onLike: () => _handleLike(controller),
              onComment: _handleComment,
              onRepost: () => _handleRepost(controller),
              isLiked: controller.isPostLiked(post.id),
              likeCount: controller.postLikeCount(post.id),
              commentCount: post.commentCount,
              repostCount: controller.postRepostCount(post.id),
            ),
          ],
        ),
      ),
    );
  }
}
