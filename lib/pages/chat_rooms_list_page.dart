// lib/pages/chat_rooms_list_page.dart
// Modern chat rooms list with grid layout and animations

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/chat_controller.dart';
import '../design_system/modern_ui_system.dart';
import '../utils/modern_color_palettes.dart';


class ModernChatRoomsListPage extends StatefulWidget {
  const ModernChatRoomsListPage({super.key});

  @override
  State<ModernChatRoomsListPage> createState() => _ModernChatRoomsListPageState();
}

class _ModernChatRoomsListPageState extends State<ModernChatRoomsListPage>
    with TickerProviderStateMixin {
  final ChatController controller = Get.find<ChatController>();
  late AnimationController _listController;
  late Animation<double> _listAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _listController = AnimationController(
      duration: DesignTokens.durationNormal,
      vsync: this,
    );

    _listAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _listController,
      curve: DesignTokens.curveEaseOut,
    ));

    _listController.forward();
  }

  @override
  void dispose() {
    _listController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _listController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _listAnimation,
            child: CustomScrollView(
              slivers: [
                _buildModernAppBar(context),
                _buildRoomsList(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildModernAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      leading: AnimatedButton(
        onPressed: () => Get.back(),
        child: Icon(
          Icons.arrow_back_rounded,
          color: context.colorScheme.primary,
        ),
      ),
      actions: [
        AnimatedButton(
          onPressed: controller.refreshRooms,
          child: Icon(
            Icons.refresh_rounded,
            color: context.colorScheme.primary,
          ),
        ),
        SizedBox(width: DesignTokens.md(context)),
      ],
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        title: Text(
          'All Chat Rooms',
          style: context.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: context.colorScheme.primary,
          ),
        ),
        titlePadding: EdgeInsets.only(
          left: DesignTokens.md(context),
          bottom: DesignTokens.md(context),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                context.colorScheme.primary.withOpacity(0.1),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoomsList(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return SliverPadding(
          padding: DesignTokens.md(context).all,
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: ResponsiveUtils.adaptiveValue(
                context,
                mobile: 2,
                tablet: 3,
                desktop: 4,
              ),
              crossAxisSpacing: DesignTokens.md(context),
              mainAxisSpacing: DesignTokens.md(context),
              childAspectRatio: 1.0,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => SkeletonLoader(
                borderRadius: BorderRadius.circular(DesignTokens.radiusLg(context)),
              ),
              childCount: 12,
            ),
          ),
        );
      }

      if (controller.rashiRooms.isEmpty) {
        return SliverFillRemaining(
          child: _buildEmptyState(context),
        );
      }

      return SliverPadding(
        padding: DesignTokens.md(context).all,
        sliver: SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: ResponsiveUtils.adaptiveValue(
              context,
              mobile: 2,
              tablet: 3,
              desktop: 4,
            ),
            crossAxisSpacing: DesignTokens.md(context),
            mainAxisSpacing: DesignTokens.md(context),
            childAspectRatio: 1.0,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final room = controller.rashiRooms[index];
              return StaggeredListItem(
                index: index,
                staggerDelay: const Duration(milliseconds: 100),
                animationDuration: const Duration(milliseconds: 500),
                child: AnimatedButton(
                  onPressed: () => Get.toNamed('/chat-room/${room.id}'),
                  child: _buildRoomCard(context, room, index),
                ),
              );
            },
            childCount: controller.rashiRooms.length,
          ),
        ),
      );
    });
  }

  Widget _buildRoomCard(BuildContext context, dynamic room, int index) {
    return GlassmorphicContainer(
      padding: DesignTokens.lg(context).all,
      borderRadius: BorderRadius.circular(DesignTokens.radiusLg(context)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: room.gradientColors),
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd(context)),
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
                  fontSize: 28,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(height: DesignTokens.md(context)),
          Text(
            room.name,
            style: context.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: DesignTokens.sm(context)),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: DesignTokens.sm(context),
              vertical: DesignTokens.xs(context),
            ),
            decoration: BoxDecoration(
              color: context.colorScheme.primaryContainer.withOpacity(0.5),
              borderRadius: BorderRadius.circular(DesignTokens.radiusSm(context)),
            ),
            child: Text(
              '${room.dailyMessages} today',
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: GlassmorphicCard(
        padding: DesignTokens.xl(context).all,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 80,
              color: context.colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            SizedBox(height: DesignTokens.lg(context)),
            Text(
              'No Chat Rooms Available',
              style: context.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: DesignTokens.sm(context)),
            Text(
              'Check back later for active discussions',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: DesignTokens.lg(context)),
            AnimatedButton(
              onPressed: controller.refreshRooms,
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
                  borderRadius: BorderRadius.circular(DesignTokens.radiusLg(context)),
                ),
                child: Text(
                  'Refresh',
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
}
