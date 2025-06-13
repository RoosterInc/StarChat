import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/chat_controller.dart';
import '../design_system/modern_ui_system.dart';
import '../features/social_feed/screens/feed_page.dart';

class ChatRoomPage extends GetView<ChatController> {
  const ChatRoomPage({super.key});

  @override
  Widget build(BuildContext context) {
    final roomId = Get.parameters['roomId']!;

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            _ChatRoomSliverAppBar(roomId: roomId),
          ],
          body: TabBarView(
            children: [
              FeedPage(roomId: roomId),
              const Center(child: Text('Events')),
              const Center(child: Text('Predictions')),
              const Center(child: Text('Weekly')),
              const Center(child: Text('Special Events')),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatRoomSliverAppBar extends GetView<ChatController> {
  final String roomId;

  const _ChatRoomSliverAppBar({required this.roomId});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: ResponsiveUtils.adaptiveValue(
        context,
        mobile: DesignTokens.xl(context) * 5,
        tablet: DesignTokens.xl(context) * 6,
        desktop: DesignTokens.xl(context) * 7,
      ),
      automaticallyImplyLeading: false,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Material(
          color: context.colorScheme.surface,
          child: const TabBar(
            tabs: [
              Tab(text: 'Feed'),
              Tab(text: 'Events'),
              Tab(text: 'Predictions'),
              Tab(text: 'Weekly'),
              Tab(text: 'Special Events'),
            ],
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: DesignTokens.md(context),
              vertical: DesignTokens.sm(context),
            ),
            child: Obx(() {
              final room = controller.getRoomById(roomId);
              final title = room?.name ?? 'Chat Room';
              const activeUsers = 0;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AccessibilityWrapper(
                    semanticLabel: 'Go Back',
                    isButton: true,
                    child: AnimatedButton(
                      onPressed: Get.back,
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: context.colorScheme.primary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      AccessibilityWrapper(
                        semanticLabel: 'Room Information',
                        isButton: true,
                        child: AnimatedButton(
                          onPressed: () {
                            Get.snackbar(
                              'Room Info',
                              'Room details and settings coming soon',
                              snackPosition: SnackPosition.BOTTOM,
                              duration: const Duration(seconds: 2),
                            );
                          },
                          child: Icon(
                            Icons.info_outline_rounded,
                            color: context.colorScheme.primary,
                          ),
                        ),
                      ),
                      SizedBox(width: DesignTokens.sm(context)),
                      CircleAvatar(
                        radius: ResponsiveUtils.adaptiveValue(
                          context,
                          mobile: DesignTokens.md(context),
                          tablet: DesignTokens.md(context) * 1.2,
                          desktop: DesignTokens.md(context) * 1.4,
                        ),
                        backgroundColor:
                            context.colorScheme.primary.withOpacity(0.1),
                        child: Text(
                          '$activeUsers',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: context.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}
