import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:validators/validators.dart';
import '../../../design_system/modern_ui_system.dart';
import '../controllers/feed_controller.dart';
import '../models/feed_post.dart';
import '../../../controllers/auth_controller.dart';

class ComposePostPage extends StatefulWidget {
  final String roomId;
  const ComposePostPage({super.key, required this.roomId});

  @override
  State<ComposePostPage> createState() => _ComposePostPageState();
}

class _ComposePostPageState extends State<ComposePostPage> {
  final _controller = TextEditingController();
  final _linkController = TextEditingController();
  XFile? _image;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _image = picked;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _linkController.dispose();
    super.dispose();
  }

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
            SizedBox(height: DesignTokens.sm(context)),
            TextField(
              controller: _linkController,
              decoration: const InputDecoration(hintText: 'Link (https://...)'),
            ),
            if (_image != null)
              Padding(
                padding: EdgeInsets.only(top: DesignTokens.sm(context)),
                child: Image.file(
                  File(_image!.path),
                  height: 150,
                ),
              ),
            SizedBox(height: DesignTokens.md(context)),
            Row(
              children: [
                AnimatedButton(
                  onPressed: _pickImage,
                  child: const Text('Add Image'),
                ),
                const Spacer(),
                AnimatedButton(
                  onPressed: () async {
                    final uid = auth.userId ?? '';
                    final uname = auth.username.value.isNotEmpty
                        ? auth.username.value
                        : 'You';
                    final linkText = _linkController.text.trim();
                    if (linkText.isNotEmpty && isURL(linkText) &&
                        linkText.startsWith('http')) {
                      final meta =
                          await feedController.service.fetchLinkMetadata(linkText);
                      await feedController.createPostWithLink(
                        uid,
                        uname,
                        _controller.text,
                        widget.roomId,
                        linkText,
                        meta,
                      );
                    } else if (_image != null) {
                      await feedController.createPostWithImage(
                        uid,
                        uname,
                        _controller.text,
                        widget.roomId,
                        File(_image!.path),
                      );
                    } else {
                      final post = FeedPost(
                        id: DateTime.now().toIso8601String(),
                        roomId: widget.roomId,
                        userId: uid,
                        username: uname,
                        content: _controller.text,
                      );
                      await feedController.createPost(post);
                    }
                    Get.back();
                  },
                  child: const Text('Post'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
