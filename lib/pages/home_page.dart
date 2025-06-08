import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../widgets/enhanced_responsive_layout.dart';
import '../widgets/adaptive_navigation.dart';
import '../widgets/sample_sliver_app_bar.dart';
import '../widgets/safe_network_image.dart';
import '../widgets/complete_persistent_watchlist.dart';
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
            opacity: value,
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
      child: CustomScrollView(
        slivers: [
          const SampleSliverAppBar(),
          SliverFillRemaining(
            child: TabBarView(
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
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, double width) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Center(
      child: Container(
        padding: EdgeInsets.all(_getResponsivePadding(context)),
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            _buildPredictionScoresSection(context),
            SizedBox(height: _getResponsiveSpacing(context)),
            Expanded(
              child: const CompletePersistentWatchlistWidget(),
            ),
          ],
        ),
      ),
    );
  }

  double _getResponsivePadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1024) return 24.0;
    if (width >= 600) return 20.0;
    return 16.0;
  }

  double _getResponsiveSpacing(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1024) return 32.0;
    if (width >= 600) return 24.0;
    return 20.0;
  }

  double _getResponsiveFontSize(BuildContext context, double baseSize) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1024) return baseSize * 1.2;
    if (width >= 600) return baseSize * 1.1;
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
        SizedBox(
          height: _getResponsiveHeight(context, 80),
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
                    scale: value,
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

  double _getResponsiveHeight(BuildContext context, double baseHeight) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1024) return baseHeight * 1.3;
    if (width >= 600) return baseHeight * 1.15;
    return baseHeight;
  }
}
