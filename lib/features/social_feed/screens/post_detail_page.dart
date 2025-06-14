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
import 'package:appwrite/appwrite.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../notifications/services/notification_service.dart';
import '../../../utils/logger.dart';
import 'package:flutter/foundation.dart';

class PostDetailPage extends StatefulWidget {
  final FeedPost post;
  const PostDetailPage({super.key, required this.post});

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final _textController = TextEditingController();
  late final CommentsController _commentsController;

  Future<void> _notifyMentions(List<String> mentions, String commentId) async {
    if (mentions.isEmpty || !Get.isRegistered<NotificationService>()) return;
    try {
      final auth = Get.find<AuthController>();
      final dbId = dotenv.env['APPWRITE_DATABASE_ID'] ?? 'StarChat_DB';
      final profilesId =
          dotenv.env['USER_PROFILES_COLLECTION_ID'] ?? 'user_profiles';
      for (final name in mentions) {
        final res = await auth.databases.listDocuments(
          databaseId: dbId,
          collectionId: profilesId,
          queries: [Query.equal('username', name)],
        );
        if (res.documents.isNotEmpty) {
          await Get.find<NotificationService>().createNotification(
            res.documents.first.data['\$id'],
            auth.userId ?? '',
            'mention',
            itemId: commentId,
            itemType: 'comment',
          );
        }
      }
    } catch (e, st) {
      logger.e('Error notifying mentions', error: e, stackTrace: st);
      if (Get.context != null) {
        Get.snackbar('Error', 'Failed to notify mentions',
            snackPosition: SnackPosition.BOTTOM);
      }
    }
  }

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
                    await _notifyMentions(mentions, comment.id);
                    await _notifyPostAuthor(widget.post.userId, widget.post.id);
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

@visibleForTesting
Future<void> notifyPostAuthorForTest(String authorId, String postId) async {
  final state = _PostDetailPageState();
  await state._notifyPostAuthor(authorId, postId);
}
