import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../design_system/modern_ui_system.dart';
import '../models/feed_post.dart';
import '../controllers/feed_controller.dart';
import '../screens/post_detail_page.dart';
import '../screens/edit_post_page.dart';
import '../screens/repost_page.dart';
import 'media_gallery.dart';
import 'reaction_bar.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../widgets/safe_network_image.dart';
import '../../discovery/screens/hashtag_search_page.dart';
import '../../bookmarks/controllers/bookmark_controller.dart';
import '../../../controllers/auth_controller.dart';
import '../../reports/screens/report_post_page.dart';
import '../../../bindings/report_binding.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../profile/screens/profile_page.dart';
import '../../../bindings/profile_binding.dart';
import 'package:appwrite/appwrite.dart';

class PostCard extends StatelessWidget {
  final FeedPost post;
  const PostCard({super.key, required this.post});

  Future<void> _openProfile(String username) async {
    final auth = Get.find<AuthController>();
    final dbId = dotenv.env['APPWRITE_DATABASE_ID'] ?? 'StarChat_DB';
    final profilesId =
        dotenv.env['USER_PROFILES_COLLECTION_ID'] ?? 'user_profiles';
    final res = await auth.databases.listDocuments(
      databaseId: dbId,
      collectionId: profilesId,
      queries: [Query.equal('username', username)],
    );
    if (res.documents.isNotEmpty) {
      Get.to(
        () => UserProfilePage(userId: res.documents.first.data['\$id']),
        binding: ProfileBinding(),
      );
    }
  }

  Widget _buildContent(BuildContext context) {
    final spans = <TextSpan>[];
    final words = post.content.split(RegExp(r'(\s+)'));
    for (final word in words) {
      if (word.startsWith('#')) {
        final tag = word.substring(1).toLowerCase();
        spans.add(TextSpan(
          text: '$word ',
          style: TextStyle(color: Theme.of(context).colorScheme.primary),
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              Get.to(() => HashtagSearchPage(hashtag: tag));
            },
        ));
      } else if (word.startsWith('@')) {
        final name = word.substring(1);
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

  void _handleLike(FeedController controller) {
    controller.toggleLikePost(post.id);
  }

  void _handleComment() {
    Get.to(() => PostDetailPage(post: post));
  }

  void _handleRepost(FeedController controller) {
    final auth = Get.find<AuthController>();
    if (controller.isPostReposted(post.id)) {
      controller.undoRepost(post.id);
    } else {
      if (auth.userId == null) {
        Get.snackbar('Error', 'Login required');
        return;
      }
      controller.repostPost(post.id);
    }
  }

  void _handleBookmark(BookmarkController controller, String userId) {
    controller.toggleBookmark(userId, post.id);
  }


  Future<void> _handleDelete(FeedController controller) async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete Post?'),
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
        await controller.deletePost(post.id);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('failed_to_delete_post'.tr),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FeedController>();
    final bookmarkController = Get.find<BookmarkController>();
    final auth = Get.find<AuthController>();
    final canEdit =
        DateTime.now().difference(post.editedAt ?? post.createdAt).inMinutes <=
            30;
    return Obx(
      () => GlassmorphicCard(
        padding: DesignTokens.md(context).all,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (controller.isPostReposted(post.id))
              Padding(
                padding: EdgeInsets.only(bottom: DesignTokens.xs(context)),
                child: Text(
                  'Reposted by you',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
            Row(
              children: [
                Text(
                  post.username,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (post.isEdited)
                  Padding(
                    padding: EdgeInsets.only(left: DesignTokens.xs(context)),
                    child: Text(
                      'Edited',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                const Spacer(),
                if (auth.userId == post.userId) ...[
                  if (canEdit)
                    AccessibilityWrapper(
                      semanticLabel: 'Edit post',
                      isButton: true,
                      child: AnimatedButton(
                        onPressed: () {
                          Get.to(() => EditPostPage(post: post));
                        },
                        child: const Text('Edit'),
                      ),
                    ),
                  if (canEdit) SizedBox(width: DesignTokens.xs(context)),
                  AccessibilityWrapper(
                    semanticLabel: 'Delete post',
                    isButton: true,
                    child: AnimatedButton(
                      onPressed: () => _handleDelete(controller),
                      child: const Text('Delete'),
                    ),
                  ),
                ]
                else if (auth.userId != null) ...[
                  AccessibilityWrapper(
                    semanticLabel: 'Report post',
                    isButton: true,
                    child: AnimatedButton(
                      onPressed: () {
                        Get.to(
                          () => ReportPostPage(postId: post.id),
                          binding: ReportBinding(),
                        );
                      },
                      child: const Text('Report'),
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(height: DesignTokens.sm(context)),
            _buildContent(context),
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
                            width: DesignTokens.spacing(context, 60),
                            height: DesignTokens.spacing(context, 60),
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
              onBookmark: () => _handleBookmark(bookmarkController, auth.userId ?? ''),
              postId: post.id,
              isReposted: controller.isPostReposted(post.id),
              isLiked: controller.isPostLiked(post.id),
              isBookmarked: bookmarkController.isBookmarked(post.id),
              likeCount: controller.postLikeCount(post.id),
              commentCount: controller.postCommentCount(post.id),
              repostCount: controller.postRepostCount(post.id),
              shareCount: post.shareCount,
            ),
          ],
        ),
      ),
    );
  }
}
