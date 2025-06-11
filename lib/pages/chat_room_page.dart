// lib/pages/modern_chat_room_page.dart
// Modern chat room with glassmorphism and advanced animations

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/chat_controller.dart';
import '../design_system/modern_ui_system.dart';
import '../utils/modern_color_palettes.dart';
import 'dart:ui';

class ChatRoomPage extends StatefulWidget {
  const ChatRoomPage({super.key});

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage>
    with TickerProviderStateMixin {
  final ChatController controller = Get.find<ChatController>();
  final TextEditingController _messageController = TextEditingController();
  late AnimationController _slideController;
  late AnimationController _bubbleController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: DesignTokens.durationNormal,
      vsync: this,
    );
    _bubbleController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: DesignTokens.curveEaseOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: DesignTokens.curveEaseOut,
    ));

    _slideController.forward();
    _bubbleController.repeat();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _bubbleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roomId = Get.parameters['roomId']!;
    
    return Scaffold(
      body: Obx(() {
        final room = controller.getRoomById(roomId);
        if (room == null) {
          return _buildErrorState(context);
        }

        return AnimatedBuilder(
          animation: _slideController,
          builder: (context, child) {
            return SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: _buildChatInterface(context, room),
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: GlassmorphicCard(
        padding: DesignTokens.xl(context).all,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: context.colorScheme.error,
            ),
            SizedBox(height: DesignTokens.lg(context)),
            Text(
              'Room Not Found',
              style: context.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: DesignTokens.sm(context)),
            Text(
              'The chat room you\'re looking for doesn\'t exist.',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: DesignTokens.lg(context)),
            AnimatedButton(
              onPressed: () => Get.back(),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: DesignTokens.lg(context),
                  vertical: DesignTokens.md(context),
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      context.colorScheme.primary,
                      context.colorScheme.secondary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(
                    DesignTokens.radiusLg(context),
                  ),
                ),
                child: Text(
                  'Go Back',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatInterface(BuildContext context, dynamic room) {
    return Column(
      children: [
        _buildModernAppBar(context, room),
        Expanded(
          child: _buildChatArea(context, room),
        ),
        _buildMessageInput(context),
      ],
    );
  }

  Widget _buildModernAppBar(BuildContext context, dynamic room) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + DesignTokens.sm(context),
        bottom: DesignTokens.md(context),
        left: DesignTokens.md(context),
        right: DesignTokens.md(context),
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: room.gradientColors.map((c) => c.withOpacity(0.1)).toList(),
        ),
      ),
      child: Row(
        children: [
          AnimatedButton(
            onPressed: () => Get.back(),
            child: GlassmorphicContainer(
              width: 40,
              height: 40,
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd(context)),
              child: Icon(
                Icons.arrow_back_rounded,
                color: context.colorScheme.primary,
                size: 20,
              ),
            ),
          ),
          SizedBox(width: DesignTokens.md(context)),
          // Room icon
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: room.gradientColors),
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd(context)),
              boxShadow: [
                BoxShadow(
                  color: room.gradientColors[0].withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                room.symbol ?? '⭐',
                style: const TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: DesignTokens.md(context)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  room.name,
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${room.dailyMessages} messages today',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          AnimatedButton(
            onPressed: () => _showRoomInfo(context, room),
            child: GlassmorphicContainer(
              width: 40,
              height: 40,
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd(context)),
              child: Icon(
                Icons.info_outline_rounded,
                color: context.colorScheme.primary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatArea(BuildContext context, dynamic room) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            context.colorScheme.surface,
            context.colorScheme.surfaceVariant.withOpacity(0.3),
          ],
        ),
      ),
      child: AnimatedBuilder(
        animation: _bubbleController,
        builder: (context, child) {
          return Stack(
            children: [
              // Floating background elements
              ...List.generate(5, (index) {
                final offset = (_bubbleController.value * 100) + (index * 50);
                return Positioned(
                  top: 100 + (index * 80.0) + (offset % 200),
                  left: 20 + (index * 60.0) + (offset % 150),
                  child: Container(
                    width: 30 + (index * 5.0),
                    height: 30 + (index * 5.0),
                    decoration: BoxDecoration(
                      color: room.gradientColors[0].withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              }),
              Center(
                child: _buildEmptyState(context, room),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, dynamic room) {
    return GlassmorphicCard(
      padding: DesignTokens.xl(context).all,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: room.gradientColors),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: room.gradientColors[0].withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              Icons.chat_bubble_rounded,
              size: 40,
              color: Colors.white,
            ),
          ),
          SizedBox(height: DesignTokens.lg(context)),
          Text(
            'Welcome to ${room.name}',
            style: context.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: DesignTokens.sm(context)),
          Text(
            'Start a conversation with other members of this rashi community',
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: DesignTokens.lg(context)),
          Container(
            padding: DesignTokens.md(context).all,
            decoration: BoxDecoration(
              color: context.colorScheme.primaryContainer.withOpacity(0.5),
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd(context)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lightbulb_outline_rounded,
                  size: 16,
                  color: context.colorScheme.onPrimaryContainer,
                ),
                SizedBox(width: DesignTokens.sm(context)),
                Text(
                  'Real-time messaging coming soon!',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(DesignTokens.md(context)),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: context.colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: GlassmorphicContainer(
                padding: const EdgeInsets.all(4),
                borderRadius: BorderRadius.circular(DesignTokens.radiusXl(context)),
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(
                      color: context.colorScheme.onSurfaceVariant.withOpacity(0.6),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(DesignTokens.radiusXl(context)),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: context.colorScheme.surfaceVariant.withOpacity(0.5),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: DesignTokens.lg(context),
                      vertical: DesignTokens.md(context),
                    ),
                    prefixIcon: AnimatedButton(
                      onPressed: () => _showEmojiPicker(context),
                      child: Icon(
                        Icons.emoji_emotions_outlined,
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  style: context.textTheme.bodyMedium,
                ),
              ),
            ),
            SizedBox(width: DesignTokens.sm(context)),
            AnimatedButton(
              onPressed: () => _sendMessage(context),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      context.colorScheme.primary,
                      context.colorScheme.secondary,
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: context.colorScheme.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.send_rounded,
                  color: context.colorScheme.onPrimary,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRoomInfo(BuildContext context, dynamic room) {
    Get.bottomSheet(
      Container(
        padding: DesignTokens.xl(context).all,
        decoration: BoxDecoration(
          color: context.colorScheme.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(DesignTokens.radiusXl(context)),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.colorScheme.onSurfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: DesignTokens.lg(context)),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: room.gradientColors),
                borderRadius: BorderRadius.circular(DesignTokens.radiusLg(context)),
                boxShadow: [
                  BoxShadow(
                    color: room.gradientColors[0].withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  room.symbol ?? '⭐',
                  style: const TextStyle(
                    fontSize: 32,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(height: DesignTokens.lg(context)),
            Text(
              room.name,
              style: context.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: DesignTokens.sm(context)),
            Text(
              'Rashi Discussion Room',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: DesignTokens.lg(context)),
            Container(
              padding: DesignTokens.md(context).all,
              decoration: BoxDecoration(
                color: context.colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd(context)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildInfoItem(
                    context,
                    'Messages Today',
                    '${room.dailyMessages}',
                    Icons.chat_bubble_outline_rounded,
                  ),
                  _buildInfoItem(
                    context,
                    'Members',
                    '1.2k',
                    Icons.people_outline_rounded,
                  ),
                  _buildInfoItem(
                    context,
                    'Activity',
                    'High',
                    Icons.trending_up_rounded,
                  ),
                ],
              ),
            ),
            SizedBox(height: DesignTokens.lg(context)),
            AnimatedButton(
              onPressed: () => Get.back(),
              child: Container(
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      context.colorScheme.primary,
                      context.colorScheme.secondary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusLg(context)),
                ),
                child: Center(
                  child: Text(
                    'Close',
                    style: context.textTheme.titleSmall?.copyWith(
                      color: context.colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          color: context.colorScheme.primary,
          size: 20,
        ),
        SizedBox(height: DesignTokens.xs(context)),
        Text(
          value,
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: context.colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: context.textTheme.bodySmall?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  void _showEmojiPicker(BuildContext context) {
    Get.snackbar(
      'Coming Soon',
      'Emoji picker will be available in the next update',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  void _sendMessage(BuildContext context) {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    MicroInteractions.lightHaptic();
    _messageController.clear();
    
    Get.snackbar(
      'Message Sent',
      'Real-time messaging will be implemented in the next phase',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
      backgroundColor: context.colorScheme.primaryContainer,
      colorText: context.colorScheme.onPrimaryContainer,
    );
  }
}

