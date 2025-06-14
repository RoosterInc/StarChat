import 'package:flutter/material.dart';
import '../../../design_system/modern_ui_system.dart';
import 'package:get/get.dart';
import '../widgets/comment_thread.dart';
import '../utils/comment_validation.dart';
import '../models/post_comment.dart';
import '../controllers/comments_controller.dart';
import '../../../controllers/auth_controller.dart';
import '../../notifications/services/mention_service.dart';
import '../../../utils/logger.dart';

class CommentThreadPage extends StatefulWidget {
  final PostComment rootComment;
  const CommentThreadPage({super.key, required this.rootComment});

  @override
  State<CommentThreadPage> createState() => _CommentThreadPageState();
}

class _CommentThreadPageState extends State<CommentThreadPage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final commentsController = Get.find<CommentsController>();
    final auth = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Thread')),
      body: Padding(
        padding: EdgeInsets.all(DesignTokens.md(context)),
        child: Column(
          children: [
            Expanded(
              child: Obx(
                () => SingleChildScrollView(
                  child: CommentThread(comment: widget.rootComment),
                ),
              ),
            ),
            SizedBox(height: DesignTokens.sm(context)),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration:
                        const InputDecoration(hintText: 'Reply to thread'),
                  ),
                ),
                SizedBox(width: DesignTokens.sm(context)),
                AnimatedButton(
                  onPressed: () async {
                    final text = _controller.text.trim();
                    if (!isValidComment(text)) {
                      Get.snackbar(
                        'error'.tr,
                        'Comment must be between 1 and 2000 characters.',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                      return;
                    }

                    final root = widget.rootComment;
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
                      postId: root.postId,
                      userId: uid,
                      username: uname,
                      parentId: root.id,
                      content: text,
                    );
                    commentsController.replyToComment(comment);
                    await Get.find<MentionService>().notifyMentions(
                      mentions,
                      actorId: uid,
                      itemId: comment.id,
                      itemType: 'comment',
                    );
                    _controller.clear();
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
