import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../design_system/modern_ui_system.dart';
import '../controllers/comments_controller.dart';
import '../models/feed_post.dart';
import '../models/post_comment.dart';
import '../../../controllers/auth_controller.dart';
import '../widgets/comment_card.dart';
import '../utils/comment_validation.dart';
import '../widgets/post_card.dart';
import '../utils/mention_notifier.dart';

class PostDetailPage extends StatefulWidget {
  final FeedPost post;
  const PostDetailPage({super.key, required this.post});

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final _textController = TextEditingController();
  late final CommentsController _commentsController;

  @override
  void initState() {
    super.initState();
    _commentsController = Get.find<CommentsController>();
    _commentsController.loadComments(widget.post.id);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Post')),
      body: Padding(
        padding: EdgeInsets.all(DesignTokens.md(context)),
        child: Column(
          children: [
            Expanded(
              child: Obx(
                () => OptimizedListView(
                  itemCount: _commentsController.comments.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) return PostCard(post: widget.post);
                    final comment = _commentsController.comments[index - 1];
                    return Padding(
                      padding: EdgeInsets.only(top: DesignTokens.sm(context)),
                      child: CommentCard(comment: comment),
                    );
                  },
                ),
              ),
            ),
            SizedBox(height: DesignTokens.sm(context)),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration:
                        const InputDecoration(hintText: 'Add a comment'),
                  ),
                ),
                SizedBox(width: DesignTokens.sm(context)),
                AnimatedButton(
                  onPressed: () async {
                    final text = _textController.text.trim();
                    if (!isValidComment(text)) {
                      Get.snackbar(
                        'error'.tr,
                        'Comment must be between 1 and 2000 characters.',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                      return;
                    }

                    final uid = auth.userId ?? '';
                    final uname = auth.username.value.isNotEmpty
                        ? auth.username.value
                        : 'You';
                    final mentions = RegExp(r'(?:@)([A-Za-z0-9_]+)')
                        .allMatches(text)
                        .map((m) => m.group(1)!)
                        .toSet()
                        .toList();
                    final comment = PostComment(
                      id: DateTime.now().toIso8601String(),
                      postId: widget.post.id,
                      userId: uid,
                      username: uname,
                      content: text,
                    );
                    _commentsController.addComment(comment);
                    await notifyMentions(
                      mentions,
                      comment.id,
                      itemType: 'comment',
                    );
                    _textController.clear();
                  },
                  child: const Text('Send'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
