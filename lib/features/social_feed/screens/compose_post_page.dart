import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:validators/validators.dart';
import 'package:html_unescape/html_unescape.dart';
import '../../../utils/logger.dart';
import '../../notifications/services/mention_service.dart';
import 'package:flutter/foundation.dart';
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

                    final text = _controller.text.trim();
                    if (text.isEmpty || text.length > 2000) {
                      Get.snackbar(
                        'error'.tr,
                        'Post must be between 1 and 2000 characters.',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                      return;
                    }

                    final sanitized = HtmlUnescape().convert(text);

                    var tags = RegExp(r'(?:#)([A-Za-z0-9_]+)')
                        .allMatches(sanitized)
                        .map((m) => m.group(1)!.toLowerCase())
                        .toSet()
                        .toList();
                    if (tags.length > 10) {
                      Get.snackbar(
                        'Hashtag limit',
                        'Only the first 10 hashtags will be used',
                      );
                      tags = tags.take(10).toList();
                    }
                    final mentions = RegExp(r'(?:@)([A-Za-z0-9_]+)')
                        .allMatches(sanitized)
                        .map((m) => m.group(1)!)
                        .toSet()
                        .toList();
                    if (tags.isNotEmpty) {
                      await feedController.service.saveHashtags(tags);
                    }
                    final linkText = _linkController.text.trim();
                    if (linkText.isNotEmpty && isURL(linkText) &&
                        linkText.startsWith('http')) {
                      await feedController.createPostWithLink(
                        uid,
                        uname,
                        sanitized,
                        widget.roomId,
                        linkText,
                        tags,
                        mentions,
                      );
                      await Get.find<MentionService>().notifyMentions(
                        mentions,
                        actorId: uid,
                        itemId: feedController.posts.first.id,
                        itemType: 'post',
                      );
                    } else if (_image != null) {
                      await feedController.createPostWithImage(
                        uid,
                        uname,
                        sanitized,
                        widget.roomId,
                        File(_image!.path),
                        tags,
                        mentions,
                      );
                      await Get.find<MentionService>().notifyMentions(
                        mentions,
                        actorId: uid,
                        itemId: feedController.posts.first.id,
                        itemType: 'post',
                      );
                    } else {
                      final post = FeedPost(
                        id: DateTime.now().toIso8601String(),
                        roomId: widget.roomId,
                        userId: uid,
                        username: uname,
                        content: sanitized,
                        hashtags: tags,
                        mentions: mentions,
                      );
                      await feedController.createPost(post);
                      await Get.find<MentionService>().notifyMentions(
                        mentions,
                        actorId: uid,
                        itemId: post.id,
                        itemType: 'post',
                      );
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
