import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../design_system/modern_ui_system.dart';
import '../controllers/feed_controller.dart';
import '../models/feed_post.dart';

/// A page that lets a user repost an existing [FeedPost] with an optional
/// comment.
///
/// The original post that will be shared is provided via [post].
///
/// Example usage:
/// ```dart
/// Get.to(() => RepostPage(post: myPost));
/// ```
class RepostPage extends StatefulWidget {
  /// The post that should be reposted.
  final FeedPost post;

  const RepostPage({super.key, required this.post});

  @override
  State<RepostPage> createState() => _RepostPageState();
}

class _RepostPageState extends State<RepostPage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feedController = Get.find<FeedController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Repost')),
      body: Padding(
        padding: EdgeInsets.all(DesignTokens.md(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.post.content,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            SizedBox(height: DesignTokens.md(context)),
            TextField(
              controller: _controller,
              maxLines: 3,
              decoration:
                  const InputDecoration(hintText: 'Add a comment (optional)'),
            ),
            SizedBox(height: DesignTokens.md(context)),
            Row(
              children: [
                const Spacer(),
                AnimatedButton(
                  onPressed: () async {
                    final comment =
                        _controller.text.trim().isEmpty ? null : _controller.text.trim();
                    await feedController.repostPost(widget.post.id, comment);
                    Get.back();
                  },
                  enableHaptics: true,
                  child: const Text('Repost'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
