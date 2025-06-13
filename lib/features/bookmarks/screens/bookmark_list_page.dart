import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../design_system/modern_ui_system.dart';
import '../controllers/bookmark_controller.dart';
import '../../social_feed/widgets/post_card.dart';
import '../../../controllers/auth_controller.dart';

class BookmarkListPage extends StatefulWidget {
  const BookmarkListPage({super.key});

  @override
  State<BookmarkListPage> createState() => _BookmarkListPageState();
}

class _BookmarkListPageState extends State<BookmarkListPage> {
  @override
  void initState() {
    super.initState();
    final userId = Get.find<AuthController>().userId;
    if (userId != null) {
      Get.find<BookmarkController>().loadBookmarks(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<BookmarkController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Bookmarks')),
      body: Obx(() {
        if (controller.isLoading.value) {
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
          itemCount: controller.bookmarks.length,
          padding: EdgeInsets.all(DesignTokens.md(context)),
          itemBuilder: (context, index) {
            final post = controller.bookmarks[index].post;
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
