import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/design_system/modern_ui_system.dart';
import '../services/feed_service.dart';

enum ReactionTarget { post, comment, repost }

class ReactionBar extends StatelessWidget {
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onRepost;
  final VoidCallback? onBookmark;
  final VoidCallback? onShare;
  final String? postId;
  final bool isLiked;
  final bool isBookmarked;
  final int likeCount;
  final int commentCount;
  final int repostCount;
  final int shareCount;
  final ReactionTarget target;
  final bool isReposted;

  const ReactionBar({
    super.key,
    this.onLike,
    this.onComment,
    this.onRepost,
    this.onBookmark,
    this.onShare,
    this.postId,
    this.isLiked = false,
    this.isBookmarked = false,
    this.likeCount = 0,
    this.commentCount = 0,
    this.repostCount = 0,
    this.shareCount = 0,
    this.target = ReactionTarget.post,
    this.isReposted = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget buildItem({
      required Widget icon,
      required String label,
      required VoidCallback? onTap,
      int? count,
    }) {
      return AccessibilityWrapper(
        semanticLabel: label,
        isButton: true,
        child: AnimatedButton(
          onPressed: onTap,
          enableHaptics: true,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            shadowColor: Colors.transparent,
            overlayColor: MaterialStateProperty.all(Colors.transparent),
            elevation: 0,
            padding: EdgeInsets.symmetric(
              horizontal: DesignTokens.sm(context),
              vertical: DesignTokens.xs(context),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              icon,
              if (count != null) ...[
                SizedBox(width: DesignTokens.xs(context)),
                Text('$count'),
              ]
            ],
          ),
        ),
      );
    }
    Future<void> defaultShare() async {
      if (postId == null) return;
      try {
        final link = await Get.find<FeedService>().sharePost(postId!);
        await Share.share('Check out this post: $link');
      } catch (_) {
        Get.snackbar("Error", "Failed to share post");
      }
    }


    String targetName() {
      switch (target) {
        case ReactionTarget.comment:
          return 'comment';
        case ReactionTarget.repost:
          return 'repost';
        case ReactionTarget.post:
        default:
          return 'post';
      }
    }

    final children = <Widget>[];

    void addItem(Widget item) {
      children.add(item);
    }

    addItem(
      buildItem(
        icon: Icon(
          isLiked ? Icons.favorite : Icons.favorite_border,
          color: isLiked
              ? context.colorScheme.primary
              : ContextExtensions(context).theme.iconTheme.color,
        ),
        label: isLiked ? 'Unlike ${targetName()}' : 'Like ${targetName()}',
        onTap: onLike,
        count: likeCount,
      ),
    );

    if (onComment != null || commentCount > 0) {
      addItem(
        buildItem(
          icon: const Icon(Icons.mode_comment_outlined),
          label: target == ReactionTarget.comment
              ? 'Reply to comment'
              : 'Comment on ${targetName()}',
          onTap: onComment,
          count: commentCount,
        ),
      );
    }

    if ((onRepost != null || repostCount > 0) && target == ReactionTarget.post) {
      addItem(
        buildItem(
          icon: Icon(
            Icons.repeat,
            color: isReposted
                ? context.colorScheme.primary
                : ContextExtensions(context).theme.iconTheme.color,
          ),
          label: isReposted ? 'Undo Repost' : 'Repost',
          onTap: onRepost,
          count: repostCount,
        ),
      );
    }

    if ((onShare != null || postId != null || shareCount > 0) &&
        target == ReactionTarget.post) {
      addItem(
        buildItem(
          icon: const Icon(Icons.share),
          label: 'Share',
          onTap: onShare ?? defaultShare,
          count: shareCount,
        ),
      );
    }

    if (onBookmark != null) {
      addItem(
        buildItem(
          icon: Icon(
            isBookmarked ? Icons.bookmark : Icons.bookmark_border,
            color: isBookmarked
                ? context.colorScheme.primary
                : ContextExtensions(context).theme.iconTheme.color,
          ),
          label: isBookmarked ? 'Remove bookmark' : 'Bookmark',
          onTap: onBookmark,
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: children
          .map((w) => Flexible(child: w))
          .toList(),
    );
  }
}
