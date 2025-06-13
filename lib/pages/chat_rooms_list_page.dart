import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/chat_controller.dart';
import '../widgets/chat/chat_room_card.dart';
import '../design_system/modern_ui_system.dart';

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
                  size: 64,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No chat rooms available',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
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
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
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
