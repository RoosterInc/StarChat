import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../design_system/modern_ui_system.dart';
import '../models/feed_post.dart';
import '../controllers/feed_controller.dart';
import '../services/mention_service.dart';

class EditPostPage extends StatefulWidget {
  final FeedPost post;
  const EditPostPage({super.key, required this.post});

  @override
  State<EditPostPage> createState() => _EditPostPageState();
}

class _EditPostPageState extends State<EditPostPage> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.post.content);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feedController = Get.find<FeedController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Post')),
      body: Padding(
        padding: EdgeInsets.all(DesignTokens.md(context)),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              maxLines: 5,
              decoration: const InputDecoration(hintText: 'Update your post'),
            ),
            SizedBox(height: DesignTokens.md(context)),
            Row(
              children: [
                const Spacer(),
                AnimatedButton(
                  onPressed: () async {
                    final tags = RegExp(r'(?:#)([A-Za-z0-9_]+)')
                        .allMatches(_controller.text)
                        .map((m) => m.group(1)!.toLowerCase())
                        .toSet()
                        .toList();
                    final mentions = RegExp(r'(?:@)([A-Za-z0-9_]+)')
                        .allMatches(_controller.text)
                        .map((m) => m.group(1)!)
                        .toSet()
                        .toList();
                    try {
                      await feedController.editPost(
                        widget.post.id,
                        _controller.text,
                        tags,
                        mentions,
                      );
                      await Get.find<MentionService>().notifyMentions(
                        mentions,
                        widget.post.id,
                        'post',
                      );
                      Get.back();
                    } catch (e) {
                      final message = e
                              .toString()
                              .contains('Edit window expired')
                          ? 'Edit window expired'
                          : 'Failed to edit post';
                      Get.snackbar(
                        'Error',
                        message,
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
