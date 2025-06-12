import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../design_system/modern_ui_system.dart';
import '../controllers/feed_controller.dart';
import '../widgets/post_card.dart';

class FeedPage extends GetView<FeedController> {
  final String roomId;
  const FeedPage({super.key, required this.roomId});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
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
    });
  }
}
