import 'package:flutter/material.dart';
import '../../../design_system/modern_ui_system.dart';
import 'package:get/get.dart';
import '../widgets/comment_card.dart';
import '../models/post_comment.dart';
import '../controllers/comments_controller.dart';
import '../../../controllers/auth_controller.dart';

class CommentThreadPage extends StatefulWidget {
  final List<PostComment> thread;
  const CommentThreadPage({super.key, required this.thread});

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
              child: OptimizedListView(
                itemCount: widget.thread.length,
                itemBuilder: (context, index) => Padding(
                  padding: EdgeInsets.only(bottom: DesignTokens.sm(context)),
                  child: CommentCard(comment: widget.thread[index]),
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
                  onPressed: () {
                    final root = widget.thread.first;
                    final uid = auth.userId ?? '';
                    final uname = auth.username.value.isNotEmpty
                        ? auth.username.value
                        : 'You';
                    final comment = PostComment(
                      id: DateTime.now().toIso8601String(),
                      postId: root.postId,
                      userId: uid,
                      username: uname,
                      parentId: root.id,
                      content: _controller.text,
                    );
                    commentsController.addComment(comment);
                    setState(() {
                      widget.thread.add(comment);
                    });
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
