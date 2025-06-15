import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:myapp/features/notifications/services/notification_service.dart';
import '../../../core/design_system/modern_ui_system.dart';
import '../controllers/comments_controller.dart';
import '../models/feed_post.dart';
import '../models/post_comment.dart';
import '../../authentication/controllers/auth_controller.dart';
import '../widgets/comment_card.dart';
import '../utils/comment_validation.dart';
import '../widgets/post_card.dart';
import '../../../shared/utils/logger.dart';
import '../services/mention_service.dart';
import 'package:flutter/foundation.dart';
import 'package:html_unescape/html_unescape.dart';

class PostDetailPage extends StatefulWidget {
  final FeedPost post;
  const PostDetailPage({super.key, required this.post});

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final _textController = TextEditingController();
  late final CommentsController commentsController;

  Future<void> _notifyPostAuthor(String authorId, String postId) async {
    if (!Get.isRegistered<NotificationService>()) return;
    try {
      final auth = Get.find<AuthController>();
      if (authorId == auth.userId) return;
      await Get.find<NotificationService>().createNotification(
        authorId,
        auth.userId ?? '',
        'comment',
        itemId: postId,
        itemType: 'post',
      );
    } catch (e, st) {
      logger.e('Error notifying post author', error: e, stackTrace: st);
    }
  }

  @override
  void initState() {
    super.initState();
    commentsController = Get.find<CommentsController>();
    commentsController.loadComments(widget.post.id);
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
              child: GetX<CommentsController>(
                builder: (controller) {
                  if (controller.isLoading) {
                    return Column(
                      children: [
                        PostCard(post: widget.post),
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
                  return OptimizedListView(
                    itemCount: controller.comments.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) return PostCard(post: widget.post);
                      final comment = controller.comments[index - 1];
                      return Padding(
                        padding: EdgeInsets.only(top: DesignTokens.sm(context)),
                        child: CommentCard(comment: comment),
                      );
                    },
                  );
                },
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
                AccessibilityWrapper(
                  semanticLabel: 'Send comment',
                  isButton: true,
                  child: AnimatedButton(
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

                    final sanitized = HtmlUnescape().convert(text);

                    final uid = auth.userId ?? '';
                    final uname = auth.username.value.isNotEmpty
                        ? auth.username.value
                        : 'You';
                    final mentions = RegExp(r'(?:@)([A-Za-z0-9_]+)')
                        .allMatches(sanitized)
                        .map((m) => m.group(1)!)
                        .toSet()
                        .toList();
                    final comment = PostComment(
                      id: DateTime.now().toIso8601String(),
                      postId: widget.post.id,
                      userId: uid,
                      username: uname,
                      content: sanitized,
                      mentions: mentions,
                    );
                    final id = await commentsController.addComment(comment);
                    await Get.find<MentionService>().notifyMentions(
                      mentions,
                      id,
                      'comment',
                    );
                    await _notifyPostAuthor(widget.post.userId, widget.post.id);
                    _textController.clear();
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
Future<void> notifyPostAuthorForTest(String authorId, String postId) async {
  final state = _PostDetailPageState();
  await state._notifyPostAuthor(authorId, postId);
}

@visibleForTesting
String sanitizeCommentForTest(String text) {
  return HtmlUnescape().convert(text.trim());
}
