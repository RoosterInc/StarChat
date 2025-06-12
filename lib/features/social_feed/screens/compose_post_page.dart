import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../design_system/modern_ui_system.dart';
import '../../controllers/auth_controller.dart';
import '../controllers/feed_controller.dart';
import '../models/feed_post.dart';

class ComposePostPage extends StatefulWidget {
  final String roomId;
  const ComposePostPage({super.key, required this.roomId});

  @override
  State<ComposePostPage> createState() => _ComposePostPageState();
}

class _ComposePostPageState extends State<ComposePostPage> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final feedController = Get.find<FeedController>();
    final auth = Get.find<AuthController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Compose Post')),
      body: Padding(
        padding: EdgeInsets.all(DesignTokens.md(context)),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              maxLines: 5,
              decoration: const InputDecoration(hintText: 'What\'s happening?'),
            ),
            SizedBox(height: DesignTokens.md(context)),
            AnimatedButton(
              onPressed: () {
                final post = FeedPost(
                  id: DateTime.now().toIso8601String(),
                  roomId: widget.roomId,
                  userId: auth.userId ?? 'me',
                  username: auth.username.value.isEmpty
                      ? 'You'
                      : auth.username.value,
                  content: _controller.text,
                );
                feedController.createPost(post);
                Get.back();
              },
              child: const Text('Post'),
            ),
          ],
        ),
      ),
    );
  }
}
