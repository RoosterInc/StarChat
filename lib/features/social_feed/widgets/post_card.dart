import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/design_system/modern_ui_system.dart';
import '../models/feed_post.dart';
import '../controllers/feed_controller.dart';
import '../screens/post_detail_page.dart';
import '../screens/edit_post_page.dart';
import 'media_gallery.dart';
import 'reaction_bar.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../shared/widgets/safe_network_image.dart';
import '../../discovery/screens/hashtag_search_page.dart';
import '../../bookmarks/controllers/bookmark_controller.dart';
import '../../authentication/controllers/auth_controller.dart';
import '../../reports/screens/report_post_page.dart';
import '../../../bindings/report_binding.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../profile/screens/profile_page.dart';
import '../../../bindings/profile_binding.dart';
import '../../profile/services/profile_service.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../profile/services/activity_service.dart';
import '../../profile/controllers/activity_controller.dart';
import '../../../shared/utils/time_utils.dart';

class PostCard extends StatelessWidget {
  final FeedPost post;
  const PostCard({super.key, required this.post});

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

  void _handleBookmark(BookmarkController controller) {
    final uid = Get.find<AuthController>().userId;
    if (uid == null) {
      Get.snackbar('Error', 'Login required');
      return;
    }
    controller.toggleBookmark(uid, post.id);
  }

  void _ensureProfileBindings() {
    final auth = Get.find<AuthController>();
    if (!Get.isRegistered<ActivityService>()) {
      Get.lazyPut<ActivityService>(
        () => ActivityService(
          databases: auth.databases,
          databaseId: dotenv.env['APPWRITE_DATABASE_ID'] ?? 'StarChat_DB',
          collectionId:
              dotenv.env['ACTIVITY_LOGS_COLLECTION_ID'] ?? 'activity_logs',
        ),
      );
      Get.lazyPut<ActivityController>(
        () => ActivityController(service: Get.find<ActivityService>()),
      );
    }
    if (!Get.isRegistered<ProfileService>()) {
      Get.lazyPut<ProfileService>(
        () => ProfileService(
          databases: auth.databases,
          databaseId: dotenv.env['APPWRITE_DATABASE_ID'] ?? 'StarChat_DB',
          profilesCollection:
              dotenv.env['USER_PROFILES_COLLECTION_ID'] ?? 'user_profiles',
          followsCollection:
              dotenv.env['FOLLOWS_COLLECTION_ID'] ?? 'follows',
          blocksCollection:
              dotenv.env['BLOCKS_COLLECTION_ID'] ?? 'blocked_users',
        ),
      );
    }
    if (!Get.isRegistered<ProfileController>()) {
      Get.lazyPut<ProfileController>(() => ProfileController());
    }
  }

  Future<void> _handleFollow() async {
    _ensureProfileBindings();
    final auth = Get.find<AuthController>();
    final uid = auth.userId;
    if (uid == null) {
      Get.snackbar('Error', 'Login required');
      return;
    }
    final service = Get.find<ProfileService>();
    final alreadyFollowing = await service.isFollowing(uid, post.userId);
    if (alreadyFollowing) return;
    await Get.find<ProfileController>().followUser(post.userId);
    Get.snackbar('Followed', 'You followed @${post.username}');
  }

  Future<void> _handleBlock() async {
    _ensureProfileBindings();
    final uid = Get.find<AuthController>().userId;
    if (uid == null) {
      Get.snackbar('Error', 'Login required');
      return;
    }
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Block User'),
        content: const Text('Are you sure you want to block this user?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Block'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await Get.find<ProfileController>().blockUser(post.userId);
      Get.snackbar('Blocked', 'User has been blocked');
    }
  }


  Future<void> _handleDelete(BuildContext context, FeedController controller) async {
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
    return InkWell(
      borderRadius: BorderRadius.circular(DesignTokens.radiusMd(context)),
      onTap: () {
        MicroInteractions.selectionHaptic();
        Get.to(() => PostDetailPage(post: post));
      },
      child: Obx(
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
                Semantics(
                  label: 'User avatar',
                  child: CircleAvatar(
                    radius: DesignTokens.spacing(context, 32) / 2,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    child: ClipOval(
                      child: SafeNetworkImage(
                        imageUrl: post.userAvatar,
                        width: DesignTokens.spacing(context, 32),
                        height: DesignTokens.spacing(context, 32),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: DesignTokens.sm(context)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (post.displayName != null && post.displayName!.isNotEmpty)
                        Text(
                          post.displayName!,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      Text(
                        '@${post.username}',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              color:
                                  Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                Text(
                  formatRelativeTime(post.createdAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                MenuAnchor(
                  builder: (context, menuController, _) => IconButton(
                    icon: const Icon(Icons.more_vert),
                    tooltip: 'Post options',
                    onPressed: menuController.open,
                  ),
                  menuChildren: [
                    if (auth.userId == post.userId && canEdit)
                      MenuItemButton(
                        onPressed: () => Get.to(() => EditPostPage(post: post)),
                        child: const Text('Edit Post'),
                      ),
                    if (auth.userId == post.userId)
                      MenuItemButton(
                        onPressed: () => _handleDelete(context, controller),
                        child: const Text('Delete Post'),
                      ),
                    if (auth.userId != post.userId && auth.userId != null)
                      MenuItemButton(
                        onPressed: () {
                          Get.to(
                            () => ReportPostPage(postId: post.id),
                            binding: ReportBinding(),
                          );
                        },
                        child: const Text('Flag or Report Post'),
                      ),
                    if (auth.userId != post.userId && auth.userId != null)
                      SubmenuButton(
                        menuChildren: [
                          MenuItemButton(
                            onPressed: _handleFollow,
                            child: const Text('Follow User'),
                          ),
                          MenuItemButton(
                            onPressed: _handleBlock,
                            child: const Text('Block User'),
                          ),
                        ],
                        child: Text('@${post.username}'),
                      ),
                  ],
                ),
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
              onBookmark: () => _handleBookmark(bookmarkController),
              postId: post.id,
              isReposted: controller.isPostReposted(post.id),
              isLiked: controller.isPostLiked(post.id),
              isBookmarked: bookmarkController.isBookmarked(post.id),
              likeCount: controller.postLikeCount(post.id),
              commentCount: controller.postCommentCount(post.id),
              repostCount: controller.postRepostCount(post.id),
              shareCount: controller.postShareCount(post.id),
              bookmarkCount: controller.postBookmarkCount(post.id),
            ),
            Padding(
              padding:
                  EdgeInsets.symmetric(vertical: DesignTokens.sm(context)),
              child: const Divider(),
            ),
          ],
        ),
      ),
    ),
  );
  }
}
