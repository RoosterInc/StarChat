import 'package:flutter/material.dart';
import 'package:myapp/core/design_system/modern_ui_system.dart';
import '../models/chat_room.dart';


class ChatRoomCard extends StatelessWidget {
  final ChatRoom room;
  final double width;
  final VoidCallback onTap;

  const ChatRoomCard({
    super.key,
    required this.room,
    required this.width,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: 90,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: room.gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: room.gradientColors.first.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(DesignTokens.spacing(context, 10)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  room.name,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: context.colorScheme.onPrimary,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: DesignTokens.sm(context),
                  vertical: DesignTokens.xs(context),
                ),
                decoration: BoxDecoration(
                  color: context.colorScheme.onPrimary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${room.dailyMessages} today',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: context.colorScheme.onPrimary,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
