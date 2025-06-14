import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../design_system/modern_ui_system.dart';
import '../controllers/feed_controller.dart';
import '../widgets/post_card.dart';
import 'compose_post_page.dart';
import '../../../controllers/auth_controller.dart';
import '../../profile/services/profile_service.dart';

class FeedPage extends StatefulWidget {
  final String roomId;
  const FeedPage({super.key, required this.roomId});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  late FeedController controller;

  Widget _buildSortMenu(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: DropdownButton<String>(
        value: controller.sortType,
        onChanged: (value) {
          if (value == null) return;
          controller.updateSortType(value);
          final auth = Get.find<AuthController>();
          List<String> blocked = [];
          if (auth.userId != null && Get.isRegistered<ProfileService>()) {
            blocked = Get.find<ProfileService>().getBlockedIds(auth.userId!);
          }
          controller.loadPosts(widget.roomId, blockedIds: blocked);
        },
        items: const [
          DropdownMenuItem(
            value: 'chronological',
            child: Text('Chronological'),
          ),
          DropdownMenuItem(
            value: 'time-based',
            child: Text('Last 24h'),
          ),
          DropdownMenuItem(
            value: 'most-commented',
            child: Text('Most Commented'),
          ),
          DropdownMenuItem(
            value: 'most-liked',
            child: Text('Most Liked'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    controller = Get.find<FeedController>();
    final auth = Get.find<AuthController>();
    List<String> blocked = [];
    if (auth.userId != null && Get.isRegistered<ProfileService>()) {
      blocked = Get.find<ProfileService>().getBlockedIds(auth.userId!);
    }
    controller.loadPosts(widget.roomId, blockedIds: blocked);
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
        return Column(
          children: [
            Padding(
              padding: EdgeInsets.all(DesignTokens.sm(context)),
              child: _buildSortMenu(context),
            ),
            Expanded(
              child: OptimizedListView(
                itemCount: controller.posts.length,
                padding: EdgeInsets.all(DesignTokens.md(context)),
                itemBuilder: (context, index) {
                  final post = controller.posts[index];
                  return Padding(
                    padding: EdgeInsets.only(bottom: DesignTokens.sm(context)),
                    child: PostCard(post: post),
                  );
                },
              ),
            ),
          ],
        );
      }),
    );
  }
}
