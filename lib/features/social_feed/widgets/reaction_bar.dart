import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import '../controllers/feed_controller.dart';

enum ReactionTarget { post, comment, repost }

class ReactionBar extends StatefulWidget {
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
  final int bookmarkCount;
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
    this.bookmarkCount = 0,
    this.target = ReactionTarget.post,
    this.isReposted = false,
  });

  @override
  _ReactionBarState createState() => _ReactionBarState();
}

class _ReactionBarState extends State<ReactionBar>
    with TickerProviderStateMixin {
  final Map<int, AnimationController> _controllers = {};

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 5; i++) {
      _controllers[i] = AnimationController(
        duration: const Duration(milliseconds: 100),
        vsync: this,
      );
    }
  }

  @override
  void dispose() {
    _controllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  Widget buildItem({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    required bool isActive,
    required Color activeColor,
    int? count,
    required int index,
  }) {
    final isEnabled = onTap != null;
    final color = isActive ? activeColor : Colors.grey[600]!;
    final animation =
        Tween<double>(begin: 1.0, end: 0.9).animate(_controllers[index]!);

    return MouseRegion(
      onEnter: (_) => _controllers[index]!.forward(),
      onExit: (_) => _controllers[index]!.reverse(),
      child: Semantics(
        label: label,
        button: true,
        enabled: isEnabled,
        child: GestureDetector(
          onTap: () {
            if (isEnabled) {
              _controllers[index]!
                  .forward()
                  .then((_) => _controllers[index]!.reverse());
              onTap();
            }
          },
          child: ScaleTransition(
            scale: animation,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16.0,
                  color: isEnabled ? color : Colors.grey[400],
                ),
                if (count != null && count > 0) ...[
                  const SizedBox(width: 4.0),
                  Text(
                    count.toString(),
                    style: TextStyle(
                      fontSize: 12.0,
                      color: isEnabled ? color : Colors.grey[400],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> defaultShare() async {
    if (widget.postId == null) return;
    try {
      final controller = Get.find<FeedController>();
      final link = await controller.sharePost(widget.postId!);
      await Share.share('Check out this post: $link');
    } catch (_) {
      Get.snackbar("Error", "Failed to share post");
    }
  }

  String targetName() {
    switch (widget.target) {
      case ReactionTarget.comment:
        return 'comment';
      case ReactionTarget.repost:
        return 'repost';
      case ReactionTarget.post:
      default:
        return 'post';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          buildItem(
            icon: widget.isLiked ? Icons.favorite : Icons.favorite_border,
            label: widget.isLiked
                ? 'Unlike ${targetName()}'
                : 'Like ${targetName()}',
            onTap: widget.onLike,
            isActive: widget.isLiked,
            activeColor: Colors.red,
            count: widget.likeCount,
            index: 0,
          ),
          if (widget.onComment != null || widget.commentCount > 0)
            buildItem(
              icon: Icons.chat_bubble_outline,
              label: widget.target == ReactionTarget.comment
                  ? 'Reply to comment'
                  : 'Comment on ${targetName()}',
              onTap: widget.onComment,
              isActive: false,
              activeColor: Colors.blue,
              count: widget.commentCount,
              index: 1,
            ),
          if ((widget.onRepost != null || widget.repostCount > 0) &&
              widget.target == ReactionTarget.post)
            buildItem(
              icon: Icons.repeat,
              label: widget.isReposted ? 'Undo Repost' : 'Repost',
              onTap: widget.onRepost,
              isActive: widget.isReposted,
              activeColor: Colors.green,
              count: widget.repostCount,
              index: 2,
            ),
          if (widget.onBookmark != null || widget.bookmarkCount > 0)
            buildItem(
              icon:
                  widget.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              label: widget.isBookmarked ? 'Remove bookmark' : 'Bookmark',
              onTap: widget.onBookmark,
              isActive: widget.isBookmarked,
              activeColor: Colors.yellow[700]!,
              count: widget.bookmarkCount,
              index: 3,
            ),
          if ((widget.onShare != null ||
                  widget.postId != null ||
                  widget.shareCount > 0) &&
              widget.target == ReactionTarget.post)
            buildItem(
              icon: Icons.share,
              label: 'Share',
              onTap: widget.onShare ?? defaultShare,
              isActive: false,
              activeColor: Colors.blue,
              count: widget.shareCount,
              index: 4,
            ),
        ],
      ),
    );
  }
}
