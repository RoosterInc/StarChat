import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../design_system/modern_ui_system.dart';
import '../controllers/feed_controller.dart';
import '../widgets/post_card.dart';
import 'compose_post_page.dart';

class FeedPage extends StatefulWidget {
  final String roomId;
  const FeedPage({super.key, required this.roomId});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  late FeedController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<FeedController>();
    controller.loadPosts(widget.roomId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: AnimatedButton(
        onPressed: () => Get.to(() => ComposePostPage(roomId: widget.roomId)),
        child: const Icon(Icons.edit),
      ),
      body: Obx(() {
        if (controller.isLoading) {
          return Padding(
            padding: EdgeInsets.all(DesignTokens.md(context)),
            child: Column(
              children: List.generate(
                3,
                (_) => Padding(
                  padding: EdgeInsets.only(bottom: DesignTokens.sm(context)),
                  child: const SkeletonLoader(height: 80),
                ),
              ),
            ),
          );
        }
        return OptimizedListView(
          itemCount: controller.posts.length,
          padding: EdgeInsets.all(DesignTokens.md(context)),
          itemBuilder: (context, index) {
            final post = controller.posts[index];
            return Padding(
              padding: EdgeInsets.only(bottom: DesignTokens.sm(context)),
              child: PostCard(post: post),
            );
          },
        );
      }),
    );
  }
}
