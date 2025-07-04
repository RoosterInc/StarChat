import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:myapp/core/design_system/modern_ui_system.dart';
import '../features/authentication/controllers/auth_controller.dart';
import '../bindings/notification_binding.dart';
import '../shared/widgets/enhanced_responsive_layout.dart';
import '../core/design_system/modern_ui_system.dart' as ui;
import '../shared/utils/modern_color_palettes.dart';
import '../shared/widgets/enhanced_sliver_app_bar.dart';
import '../shared/widgets/simple_astrologer_fab.dart';
import '../features/profile/controllers/user_type_controller.dart';
import '../controllers/enhanced_planet_house_controller.dart';
import '../shared/widgets/safe_network_image.dart';
import '../shared/widgets/complete_enhanced_watchlist.dart';
import '../features/chat/controllers/chat_controller.dart';
import '../features/chat/widgets/modern_chat_room_card.dart';
import '../shared/widgets/responsive_sizes.dart';
import 'empty_page.dart';
import '../features/search/screens/search_page.dart';
import '../features/notifications/screens/notification_page.dart';
import '../features/notifications/controllers/notification_controller.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late final NotificationController _notificationController;
  int _selectedIndex = 0;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    Get.put(WatchlistController(), permanent: true);
    final phc = Get.put(EnhancedPlanetHouseController(), permanent: true);
    phc.initialize();
    if (!Get.isRegistered<NotificationController>()) {
      NotificationBinding().dependencies();
    }
    _notificationController = Get.find<NotificationController>();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
            CurvedAnimation(
                parent: _slideController, curve: Curves.easeOutCubic));
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  List<NavigationDestination> _buildDestinations(BuildContext context) {
    final unread = _notificationController.unreadCount.value;
    return [
      const NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home'),
      const NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: 'Dashboard'),
      const NavigationDestination(
          icon: Icon(Icons.search_outlined),
          selectedIcon: Icon(Icons.search),
          label: 'Search'),
      const NavigationDestination(
          icon: Icon(Icons.favorite_outline),
          selectedIcon: Icon(Icons.favorite),
          label: 'Match'),
      NavigationDestination(
        icon: _notificationIcon(context, unread, false),
        selectedIcon: _notificationIcon(context, unread, true),
        label: 'Notifications',
      ),
      const NavigationDestination(
          icon: Icon(Icons.storefront_outlined),
          selectedIcon: Icon(Icons.storefront),
          label: 'Marketplace'),
    ];
  }

  Widget _notificationIcon(
      BuildContext context, int count, bool selected) {
    return Stack(
      children: [
        Icon(selected ? Icons.notifications : Icons.notifications_none),
        if (count > 0)
          Positioned(
            right: 0,
            child: Semantics(
              label: '$count unread notifications',
              child: Container(
                padding: EdgeInsets.all(ui.DesignTokens.xs(context)),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$count',
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(
                        color: Theme.of(context).colorScheme.onError,
                      ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final isLargeScreen = ui.ResponsiveUtils.isDesktop(context);

    final pages = [
      _buildHomeBody(context),
      const SearchPage(),
      const EmptyPage(),
      const NotificationPage(),
      const EmptyPage(),
      const EmptyPage(),
    ];

    return Obx(() => AdaptiveNavigation(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            setState(() => _selectedIndex = index);
            _slideController.reset();
            _slideController.forward();
          },
          destinations: _buildDestinations(context),
          body: Scaffold(
            drawer: !isLargeScreen ? _buildDrawer(context, authController) : null,
            floatingActionButton: const SimpleAstrologerFAB(),
            body: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: pages[_selectedIndex],
              ),
            ),
          ),
        ));
  }

  Widget _buildDrawer(BuildContext context, AuthController authController) {
    final userTypeController = Get.find<UserTypeController>();
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Obx(() {
            final username = authController.username.value;
            final userType = userTypeController.userTypeRx.value;
            return UserAccountsDrawerHeader(
              currentAccountPicture: Hero(
                tag: 'profile_avatar',
                child: CircleAvatar(
                  child: ClipOval(
                    child: SafeNetworkImage(
                      imageUrl: authController.profilePictureUrl.value,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorWidget: const Icon(Icons.person, size: 40),
                    ),
                  ),
                ),
              ),
              accountName: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  '$username ($userType)',
                  key: ValueKey('$username-$userType'),
                ),
              ),
              accountEmail: null,
            );
          }),
          _buildAnimatedListTile(
            icon: Icons.person,
            title: 'profile'.tr,
            onTap: () {
              Navigator.pop(context);
              Get.toNamed('/profile');
            },
            delay: 100,
          ),
          _buildAnimatedListTile(
            icon: Icons.settings,
            title: 'settings'.tr,
            onTap: () {
              Navigator.pop(context);
              Get.toNamed('/settings');
            },
            delay: 200,
          ),
          _buildAnimatedListTile(
            icon: Icons.bookmark,
            title: 'bookmarks'.tr,
            onTap: () {
              Navigator.pop(context);
              Get.toNamed('/bookmarks');
            },
            delay: 250,
          ),
          _buildAnimatedListTile(
            icon: Icons.logout,
            title: 'logout'.tr,
            onTap: () async {
              Navigator.pop(context);
              Get.closeAllSnackbars();
              await authController.logout();
            },
            delay: 300,
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedListTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required int delay,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(50 * (1 - value), 0),
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: ListTile(
              leading: Icon(icon),
              title: Text(title),
              onTap: onTap,
            ),
          ),
        );
      },
    );
  }

  Widget _buildHomeBody(BuildContext context) {
    final userTypeController = Get.put(UserTypeController());
    return Obx(() {
      final isAstrologer = userTypeController.isAstrologerRx.value;
      final tabLength = isAstrologer ? 6 : 5;
      return DefaultTabController(
        length: tabLength,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            const EnhancedSliverAppBar(),
          ],
          body: TabBarView(
            children: [
              EnhancedResponsiveLayout(
                mobile: (context) => _buildContent(context,
                    ui.ResponsiveUtils.fluidSize(context, min: 280, max: 400)),
                tablet: (context) => _buildContent(context, 600),
                desktop: (context) => _buildContent(context, 800),
              ),
              const Center(child: SizedBox()),
              const Center(child: SizedBox()),
              const Center(child: SizedBox()),
              const Center(child: SizedBox()),
              if (isAstrologer) const Center(child: SizedBox()),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildContent(BuildContext context, double width) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(_getResponsivePadding(context)),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: width),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPredictionScoresSection(context),
              SizedBox(height: _getResponsiveSpacing(context)),
              _buildChatRoomsSection(context),
              SizedBox(height: _getResponsiveSpacing(context)),
              SizedBox(
                height: ui.ResponsiveUtils.fluidSize(
                  context,
                  min: 200,
                  max: 400,
                ),
                child: const EnhancedWatchlistWidget(),
              ),
              SizedBox(height: _getResponsiveSpacing(context)),
            ],
          ),
        ),
      ),
    );
  }

  double _getResponsivePadding(BuildContext context) {
    return ui.ResponsiveUtils.adaptiveValue(
      context,
      mobile: ui.DesignTokens.md(context),
      tablet: ui.DesignTokens.lg(context),
      desktop: ui.DesignTokens.xl(context),
    );
  }

  double _getResponsiveSpacing(BuildContext context) {
    return ui.ResponsiveUtils.adaptiveValue(
      context,
      mobile: ui.DesignTokens.md(context),
      tablet: ui.DesignTokens.lg(context),
      desktop: ui.DesignTokens.xl(context),
    );
  }

  double _getResponsiveFontSize(BuildContext context, double baseSize) {
    final scale = ui.ResponsiveUtils.adaptiveValue(
      context,
      mobile: 1.0,
      tablet: 1.05,
      desktop: 1.1,
    );
    return baseSize * scale;
  }

  Widget _buildPredictionScoresSection(BuildContext context) {
    final names = [
      'Aries',
      'Taurus',
      'Gemini',
      'Cancer',
      'Leo',
      'Virgo',
      'Libra',
      'Scorpio',
      'Sagittarius',
      'Capricorn',
      'Aquarius',
      'Pisces',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Prediction Scores',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: _getResponsiveFontSize(context, 18),
              ),
        ),
        SizedBox(height: _getResponsiveSpacing(context) * 0.5),
        ConstrainedBox(
          constraints:
              BoxConstraints(maxHeight: _getResponsiveHeight(context, 80)),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: names.length,
            separatorBuilder: (_, __) =>
                SizedBox(width: _getResponsiveSpacing(context) * 0.4),
            itemBuilder: (context, index) {
              final color =
                  ModernColorPalettes.getGradientForIndex(index).first;
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 200 + (index * 50)),
                curve: Curves.easeOutBack,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value.clamp(0.0, 1.0),
                    child: _buildPredictionCard(
                        context, names[index], index + 1, color),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPredictionCard(
      BuildContext context, String name, int number, Color color) {
    return GestureDetector(
      onTap: () => _showPredictionDialog(name),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: _getResponsiveHeight(context, 25),
              backgroundColor: color,
              child: Text(
                '$number',
                style: TextStyle(
                  color: context.colorScheme.onPrimary,
                  fontSize: _getResponsiveFontSize(context, 16),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: _getResponsiveSpacing(context) * 0.25),
            Text(
              name,
              style: TextStyle(fontSize: _getResponsiveFontSize(context, 12)),
            ),
          ],
        ),
      ),
    );
  }

  void _showPredictionDialog(String name) {
    Get.dialog(
      AlertDialog(
        title: Text(name),
        content: const Text('R\u0101si details coming soon'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('OK'),
          ),
        ],
      ),
      transitionDuration: const Duration(milliseconds: 300),
      transitionCurve: Curves.easeInOut,
    );
  }

  Widget _buildChatRoomsSection(BuildContext context) {
    final chatController = Get.find<ChatController>();

    double getOptimalHeight() {
      return ui.ResponsiveUtils.adaptiveValue(
        context,
        mobile: 140.0,
        tablet: 160.0,
        desktop: 200.0,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Chat Rooms',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: _getResponsiveFontSize(context, 18),
                    fontWeight: FontWeight.w600,
                  ),
            ),
            TextButton(
              onPressed: () => Get.toNamed('/chat-rooms-list'),
              child: Text(
                'View All',
                style: TextStyle(
                  fontSize: _getResponsiveFontSize(context, 14),
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: _getResponsiveSpacing(context) * 0.5),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: getOptimalHeight(),
            minHeight: 140.0,
          ),
          child: Obx(() {
            if (chatController.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }
            if (chatController.rashiRooms.isEmpty) {
              return Center(
                child: Text(
                  'No chat rooms available',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              );
            }
            return ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              itemCount: chatController.rashiRooms.length,
              separatorBuilder: (_, __) =>
                  SizedBox(width: _getResponsiveSpacing(context) * 0.6),
              itemBuilder: (context, index) {
                final room = chatController.rashiRooms[index];
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 300 + (index * 100)),
                  curve: Curves.easeOutBack,
                  builder: (context, value, child) {
                    final clampedValue = value.clamp(0.0, 1.0);
                    final scale = 0.8 + (0.2 * clampedValue);
                    return Transform.scale(
                      scale: scale,
                      child: Opacity(
                        opacity: clampedValue,
                        child: ModernChatRoomCard(
                          room: room,
                          width: _getResponsiveChatCardWidth(context),
                          onTap: () => Get.toNamed('/chat-room/${room.id}'),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          }),
        ),
      ],
    );
  }

  double _getResponsiveChatCardWidth(BuildContext context) {
    final availableWidth = context.screenWidth;
    return ResponsiveSizes.chatRoomItemWidth(context, availableWidth);
  }

  double _getResponsiveHeight(BuildContext context, double baseHeight) {
    final scale = ui.ResponsiveUtils.adaptiveValue(
      context,
      mobile: 1.0,
      tablet: 1.05,
      desktop: 1.1,
    );
    return baseHeight * scale;
  }
}
