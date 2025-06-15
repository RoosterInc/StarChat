import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/design_system/modern_ui_system.dart';
import '../controllers/chat_controller.dart';
import '../widgets/chat_room_card.dart';


class ChatRoomsListPage extends GetView<ChatController> {
  const ChatRoomsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Chat Rooms'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.refreshRooms,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: SkeletonLoader(
              height: DesignTokens.xl(context),
              width: DesignTokens.xl(context),
            ),
          );
        }
        if (controller.rashiRooms.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: DesignTokens.spacing(context, 64),
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withOpacity(0.5),
                ),
                SizedBox(height: DesignTokens.md(context)),
                Text(
                  'No chat rooms available',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SizedBox(height: DesignTokens.sm(context)),
                Text(
                  'Check back later for active discussions',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          );
        }
        return GridView.builder(
          padding: DesignTokens.md(context).all,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount:
                ResponsiveUtils.isMobile(context) ? 2 : 3,
            crossAxisSpacing: DesignTokens.md(context),
            mainAxisSpacing: DesignTokens.md(context),
            childAspectRatio: 1.0,
          ),
          itemCount: controller.rashiRooms.length,
          itemBuilder: (context, index) {
            final room = controller.rashiRooms[index];
            return ChatRoomCard(
              room: room,
              width: double.infinity,
              onTap: () => Get.toNamed('/chat-room/${room.id}'),
            );
          },
        );
      }),
    );
  }
}
