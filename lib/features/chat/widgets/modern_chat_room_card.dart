import 'package:flutter/material.dart';
import 'package:myapp/core/design_system/modern_ui_system.dart';
import 'dart:ui';
import '../models/chat_room.dart';


class ModernChatRoomCard extends StatefulWidget {
  final ChatRoom room;
  final double width;
  final VoidCallback onTap;

  const ModernChatRoomCard({
    super.key,
    required this.room,
    required this.width,
    required this.onTap,
  });

  @override
  State<ModernChatRoomCard> createState() => _ModernChatRoomCardState();
}

class _ModernChatRoomCardState extends State<ModernChatRoomCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _elevationAnimation = Tween<double>(
      begin: 2.0,
      end: 8.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _animationController.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _animationController.reverse();
      },
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: GestureDetector(
              onTap: widget.onTap,
              child: Container(
                width: widget.width,
                height: 110,
                margin: const EdgeInsets.all(4),
                child: Stack(
                  children: [
                    // Background gradient
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: widget.room.gradientColors.map((color) => 
                            color.withOpacity(0.6)
                          ).toList(),
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    
                    // Glassmorphism effect
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                context.glassOverlayHigh,
                                context.glassOverlayLow,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: context.glassBorderColor,
                              width: 1.5,
                            ),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: widget.room.gradientColors.first
                                      .withOpacity(0.2),
                                  blurRadius: _elevationAnimation.value,
                                  offset: Offset(0, _elevationAnimation.value / 2),
                                ),
                                BoxShadow(
                                  color: context.colorScheme.shadow
                                      .withOpacity(isDark ? 0.3 : 0.1),
                                  blurRadius: _elevationAnimation.value * 2,
                                  offset: Offset(0, _elevationAnimation.value),
                                ),
                              ],
                            ),
                            child: _buildCardContent(context, isDark),
                          ),
                        ),
                      ),
                    ),
                    
                    // Floating message count badge
                    Positioned(
                      top: 8,
                      right: 8,
                      child: _buildMessageBadge(context, isDark),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCardContent(BuildContext context, bool isDark) {
    return Padding(
      padding: DesignTokens.md(context).all,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Room symbol and name
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: widget.room.gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: widget.room.gradientColors.first.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    widget.room.symbol ?? '⭐',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: context.colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.room.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: context.colorScheme.onSurface,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Rashi Discussion',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: context.colorScheme.onSurfaceVariant,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const Spacer(),
          
          // Activity indicator
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _getActivityColor(),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _getActivityColor().withOpacity(0.6),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _getActivityText(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: context.colorScheme.onSurface.withOpacity(0.8),
                  letterSpacing: 0.2,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: context.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBadge(BuildContext context, bool isDark) {
    return AnimatedScale(
      scale: _isHovered ? 1.1 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              context.glassOverlayHigh,
              context.glassOverlayLow,
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: context.glassBorderColor,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: context.colorScheme.shadow.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          '${widget.room.dailyMessages}',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: context.colorScheme.onSurface,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  Color _getActivityColor() {
    if (widget.room.dailyMessages > 150) return Colors.green;
    if (widget.room.dailyMessages > 100) return Colors.orange;
    return Colors.red;
  }

  String _getActivityText() {
    if (widget.room.dailyMessages > 150) return 'Very Active';
    if (widget.room.dailyMessages > 100) return 'Active';
    return 'Quiet';
  }
}
