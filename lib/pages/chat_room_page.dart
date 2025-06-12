import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/chat_controller.dart';
import '../features/social_feed/screens/feed_page.dart';

class ChatRoomPage extends GetView<ChatController> {
  const ChatRoomPage({super.key});

  @override
  Widget build(BuildContext context) {
    final roomId = Get.parameters['roomId']!;
    return Scaffold(
      appBar: AppBar(
        title: Obx(() {
          final room = controller.getRoomById(roomId);
          return Text(
            room?.name ?? 'Chat Room',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          );
        }),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              Get.snackbar(
                'Room Info',
                'Room details and settings coming soon',
                snackPosition: SnackPosition.BOTTOM,
                duration: const Duration(seconds: 2),
              );
            },
          ),
        ],
      ),
      body: FeedPage(roomId: roomId),
    );
  }
}
