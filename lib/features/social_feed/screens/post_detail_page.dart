import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../design_system/modern_ui_system.dart';
import '../../controllers/auth_controller.dart';
import '../controllers/comments_controller.dart';
import '../models/feed_post.dart';
import '../models/post_comment.dart';
import '../widgets/comment_card.dart';
import '../widgets/post_card.dart';

class PostDetailPage extends StatefulWidget {
  final FeedPost post;
  const PostDetailPage({super.key, required this.post});

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  late CommentsController controller;
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    controller = Get.find<CommentsController>();
    controller.loadComments(widget.post.id);
  }

  void _submit() {
    final auth = Get.find<AuthController>();
    final uid = auth.userId;
    if (uid == null || _textController.text.trim().isEmpty) return;
    final comment = PostComment(
      id: DateTime.now().toIso8601String(),
      postId: widget.post.id,
      userId: uid,
      username: auth.username.value,
      content: _textController.text.trim(),
    );
    controller.addComment(comment);
    _textController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post')),
      body: Column(
        children: [
          Expanded(
            child: Obx(() => OptimizedListView(
                  padding: EdgeInsets.all(DesignTokens.md(context)),
                  itemCount: controller.comments.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) return PostCard(post: widget.post);
                    final comment = controller.comments[index - 1];
                    return Padding(
                      padding: EdgeInsets.only(top: DesignTokens.sm(context)),
                      child: CommentCard(comment: comment),
                    );
                  },
                )),
          ),
          Padding(
            padding: EdgeInsets.all(DesignTokens.md(context)),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration:
                        const InputDecoration(hintText: 'Write a comment...'),
                  ),
                ),
                SizedBox(width: DesignTokens.sm(context)),
                AnimatedButton(
                  onPressed: _submit,
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
