import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../widgets/enhanced_responsive_layout.dart';
import '../widgets/adaptive_navigation.dart';
import '../widgets/sample_sliver_app_bar.dart';
import '../widgets/safe_network_image.dart';
import '../widgets/complete_enhanced_watchlist.dart';
import '../controllers/chat_controller.dart';
import '../widgets/chat/chat_room_card.dart';
import 'empty_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    Get.put(WatchlistController(), permanent: true);
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

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final screenSize = MediaQuery.of(context).size;
    final isLargeScreen = screenSize.width >= 1024;

    final pages = [
      _buildHomeBody(context),
      const EmptyPage(),
      const EmptyPage(),
      const EmptyPage(),
      const EmptyPage(),
      const EmptyPage(),
    ];

    return AdaptiveNavigation(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) {
        setState(() => _selectedIndex = index);
        _slideController.reset();
        _slideController.forward();
      },
      body: Scaffold(
        drawer: !isLargeScreen ? _buildDrawer(context, authController) : null,
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: pages[_selectedIndex],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, AuthController authController) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Obx(() => UserAccountsDrawerHeader(
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
                    authController.username.value,
                    key: ValueKey(authController.username.value),
                  ),
                ),
                accountEmail: null,
              )),
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
    return DefaultTabController(
      length: 5,
      child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          const SampleSliverAppBar(),
        ],
        body: TabBarView(
          children: [
            EnhancedResponsiveLayout(
              mobile: (context) => _buildContent(
                  context, MediaQuery.of(context).size.width * 0.95),
              tablet: (context) => _buildContent(context, 600),
              desktop: (context) => _buildContent(context, 800),
            ),
            const Center(child: SizedBox()),
            const Center(child: SizedBox()),
            const Center(child: SizedBox()),
            const Center(child: SizedBox()),
          ],
        ),
      ),
    );
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
                height: MediaQuery.of(context).size.height * 0.5,
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
    final width = MediaQuery.of(context).size.width;
    if (width >= 1024) return 16.0;
    if (width >= 600) return 14.0;
    return 12.0;
  }

  double _getResponsiveSpacing(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1024) return 28.0;
    if (width >= 600) return 22.0;
    return 18.0;
  }

  double _getResponsiveFontSize(BuildContext context, double baseSize) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1024) return baseSize * 1.1;
    if (width >= 600) return baseSize * 1.05;
    return baseSize;
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
              final color = Colors.primaries[index % Colors.primaries.length];
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
                  color: Colors.white,
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
          constraints:
              BoxConstraints(maxHeight: _getResponsiveHeight(context, 90)),
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
                        child: ChatRoomCard(
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
    final width = MediaQuery.of(context).size.width;
    if (width >= 1024) return 120.0;
    if (width >= 600) return 110.0;
    return 100.0;
  }

  double _getResponsiveHeight(BuildContext context, double baseHeight) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1024) return baseHeight * 1.1;
    if (width >= 600) return baseHeight * 1.05;
    return baseHeight;
  }
}
