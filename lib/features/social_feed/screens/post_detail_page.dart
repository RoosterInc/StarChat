import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../design_system/modern_ui_system.dart';
import '../controllers/comments_controller.dart';
import '../models/feed_post.dart';
import '../models/post_comment.dart';
import '../../../controllers/auth_controller.dart';
import '../widgets/comment_card.dart';
import '../widgets/post_card.dart';

class PostDetailPage extends StatefulWidget {
  final FeedPost post;
  const PostDetailPage({super.key, required this.post});

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final commentsController = Get.find<CommentsController>();
    commentsController.loadComments(widget.post.id);
    final auth = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Post')),
      body: Padding(
        padding: EdgeInsets.all(DesignTokens.md(context)),
        child: Column(
          children: [
            Expanded(
              child: OptimizedListView(
                itemCount: commentsController.comments.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) return PostCard(post: widget.post);
                  final comment = commentsController.comments[index - 1];
                  return Padding(
                    padding: EdgeInsets.only(top: DesignTokens.sm(context)),
                    child: CommentCard(comment: comment),
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
                AnimatedButton(
                  onPressed: () {
                    final uid = auth.userId ?? '';
                    final uname = auth.username.value.isNotEmpty
                        ? auth.username.value
                        : 'You';
                    final comment = PostComment(
                      id: DateTime.now().toIso8601String(),
                      postId: widget.post.id,
                      userId: uid,
                      username: uname,
                      content: _textController.text,
                    );
                    commentsController.addComment(comment);
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
