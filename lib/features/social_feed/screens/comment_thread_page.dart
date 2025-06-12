import 'package:flutter/material.dart';
import '../../../design_system/modern_ui_system.dart';
import '../widgets/comment_card.dart';
import '../models/post_comment.dart';

class CommentThreadPage extends StatelessWidget {
  final List<PostComment> thread;
  const CommentThreadPage({super.key, required this.thread});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thread')),
      body: OptimizedListView(
        padding: EdgeInsets.all(DesignTokens.md(context)),
        itemCount: thread.length,
        itemBuilder: (context, index) => Padding(
          padding: EdgeInsets.only(bottom: DesignTokens.sm(context)),
          child: CommentCard(comment: thread[index]),
        ),
      ),
    );
  }
}
