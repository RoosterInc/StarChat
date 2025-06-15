import 'package:flutter/material.dart';
import '../../../design_system/modern_ui_system.dart';
import 'package:get/get.dart';
import '../widgets/comment_thread.dart';
import '../utils/comment_validation.dart';
import '../models/post_comment.dart';
import '../controllers/comments_controller.dart';
import '../widgets/comment_card.dart';
import '../../../controllers/auth_controller.dart';
import 'package:appwrite/appwrite.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/mention_service.dart';
import '../../../utils/logger.dart';
import 'package:flutter/foundation.dart';
import 'package:html_unescape/html_unescape.dart';

class CommentThreadPage extends StatefulWidget {
  final PostComment rootComment;
  const CommentThreadPage({super.key, required this.rootComment});

  @override
  State<CommentThreadPage> createState() => _CommentThreadPageState();
}

class _CommentThreadPageState extends State<CommentThreadPage> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    final commentsController = Get.find<CommentsController>();
    if (commentsController.comments.isEmpty ||
        commentsController.comments.first.postId !=
            widget.rootComment.postId) {
      commentsController.loadComments(widget.rootComment.postId);
    }
  }

  Future<void> _notifyParentAuthor(String authorId, String commentId) async {
    if (!Get.isRegistered<NotificationService>()) return;
    try {
      final auth = Get.find<AuthController>();
      if (authorId == auth.userId) return;
      await Get.find<NotificationService>().createNotification(
        authorId,
        auth.userId ?? '',
        'reply',
        itemId: commentId,
        itemType: 'comment',
      );
    } catch (e, st) {
      logger.e('Error notifying parent author', error: e, stackTrace: st);
    }
  }

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
              child: Obx(() {
                if (commentsController.isLoading) {
                  return Column(
                    children: [
                      CommentCard(comment: widget.rootComment),
                      SizedBox(height: DesignTokens.sm(context)),
                      ...List.generate(
                        3,
                        (_) => Padding(
                          padding:
                              EdgeInsets.only(bottom: DesignTokens.sm(context)),
                          child: SkeletonLoader(
                            height: DesignTokens.xl(context),
                          ),
                        ),
                      ),
                    ],
                  );
                }
                return SingleChildScrollView(
                  child: CommentThread(comment: widget.rootComment),
                );
              }),
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
                AccessibilityWrapper(
                  semanticLabel: 'Send reply',
                  isButton: true,
                  child: AnimatedButton(
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
                    final sanitized = HtmlUnescape().convert(text);

                    final mentions = RegExp(r'(?:@)([A-Za-z0-9_]+)')
                        .allMatches(sanitized)
                        .map((m) => m.group(1)!)
                        .toSet()
                        .toList();
                    if (mentions.length > 10) {
                      Get.snackbar(
                        'Mention limit',
                        'Only the first 10 mentions will be used',
                      );
                      mentions = mentions.take(10).toList();
                    }
                    final comment = PostComment(
                      id: DateTime.now().toIso8601String(),
                      postId: root.postId,
                      userId: uid,
                      username: uname,
                      parentId: root.id,
                      content: sanitized,
                      mentions: mentions,
                    );
                    final id = await commentsController.replyToComment(comment);
                    await Get.find<MentionService>().notifyMentions(
                      mentions,
                      id,
                      'comment',
                    );
                    await _notifyParentAuthor(root.userId, root.id);
                    _controller.clear();
                  },
                  child: const Text('Send'),
                ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

@visibleForTesting
Future<void> notifyParentAuthorForTest(
  String authorId,
  String commentId,
) async {
  final state = _CommentThreadPageState();
  await state._notifyParentAuthor(authorId, commentId);
}

@visibleForTesting
String sanitizeCommentThreadForTest(String text) {
  return HtmlUnescape().convert(text.trim());
}
