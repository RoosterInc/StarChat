import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:validators/validators.dart';
import 'package:appwrite/appwrite.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../notifications/services/notification_service.dart';
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

  Future<void> _notifyMentions(List<String> mentions, String itemId) async {
    if (mentions.isEmpty || !Get.isRegistered<NotificationService>()) return;
    final auth = Get.find<AuthController>();
    final dbId = dotenv.env['APPWRITE_DATABASE_ID'] ?? 'StarChat_DB';
    final profilesId =
        dotenv.env['USER_PROFILES_COLLECTION_ID'] ?? 'user_profiles';
    for (final name in mentions) {
      try {
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
            itemId: itemId,
            itemType: 'post',
          );
        }
      } catch (_) {}
    }
  }

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
                    if (tags.isNotEmpty) {
                      await feedController.service.saveHashtags(tags);
                    }
                    final linkText = _linkController.text.trim();
                    if (linkText.isNotEmpty && isURL(linkText) &&
                        linkText.startsWith('http')) {
                      await feedController.createPostWithLink(
                        uid,
                        uname,
                        _controller.text,
                        widget.roomId,
                        linkText,
                        tags,
                        mentions,
                      );
                      await _notifyMentions(
                        mentions,
                        feedController.posts.first.id,
                      );
                    } else if (_image != null) {
                      await feedController.createPostWithImage(
                        uid,
                        uname,
                        _controller.text,
                        widget.roomId,
                        File(_image!.path),
                        tags,
                        mentions,
                      );
                      await _notifyMentions(
                        mentions,
                        feedController.posts.first.id,
                      );
                    } else {
                      final post = FeedPost(
                        id: DateTime.now().toIso8601String(),
                        roomId: widget.roomId,
                        userId: uid,
                        username: uname,
                        content: _controller.text,
                        hashtags: tags,
                        mentions: mentions,
                      );
                      await feedController.createPost(post);
                      await _notifyMentions(mentions, post.id);
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
