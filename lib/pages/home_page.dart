import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/sample_sliver_app_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Obx(
                () => UserAccountsDrawerHeader(
                  currentAccountPicture: CircleAvatar(
                    backgroundImage: authController
                            .profilePictureUrl.value.isNotEmpty
                        ? NetworkImage(authController.profilePictureUrl.value)
                        : null,
                    child: authController.profilePictureUrl.value.isEmpty
                        ? const Icon(Icons.person, size: 40)
                        : null,
                  ),
                  accountName: Text(authController.username.value),
                  accountEmail: null,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.person),
                title: Text('profile'.tr),
                onTap: () {
                  Navigator.pop(context);
                  Get.toNamed('/profile');
                },
              ),
              ListTile(
                leading: const Icon(Icons.switch_account),
                title: Text('manage_accounts'.tr),
                onTap: () {
                  Navigator.pop(context);
                  Get.toNamed('/accounts');
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: Text('settings'.tr),
                onTap: () {
                  Navigator.pop(context);
                  Get.toNamed('/settings');
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: Text('logout'.tr),
                onTap: () async {
                  Navigator.pop(context);
                  Get.closeAllSnackbars();
                  await authController.logout();
                },
              ),
            ],
          ),
        ),
        body: CustomScrollView(
          slivers: [
            const SampleSliverAppBar(),
            SliverFillRemaining(
              child: TabBarView(
                children: [
                  ResponsiveLayout(
                    mobile: (_) => _buildContent(
                        context, MediaQuery.of(context).size.width * 0.9),
                    tablet: (_) => _buildContent(context, 500),
                    desktop: (_) => _buildContent(context, 600),
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
        bottomNavigationBar: BottomNavigationBar(
          showSelectedLabels: false,
          showUnselectedLabels: false,
          currentIndex: _selectedIndex,
          type: BottomNavigationBarType.fixed,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search_outlined),
              activeIcon: Icon(Icons.search),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_outline),
              activeIcon: Icon(Icons.favorite),
              label: 'Match',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications_none),
              activeIcon: Icon(Icons.notifications),
              label: 'Notifications',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.storefront_outlined),
              activeIcon: Icon(Icons.storefront),
              label: 'Marketplace',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, double width) {
    final authController = Get.find<AuthController>();
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            _buildPredictionScoresSection(context),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Watch List',
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            const SizedBox(height: 8),
            Expanded(child: _buildWatchListSection(context)),
          ],
        ),
      ),
    );
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
        Text('Prediction Scores',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: names.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final color = Colors.primaries[index % Colors.primaries.length];
              return GestureDetector(
                onTap: () => Get.dialog(
                  AlertDialog(
                    title: Text(names[index]),
                    content: const Text('R\u0101si details coming soon'),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      backgroundColor: color,
                      child: Text('${index + 1}'),
                    ),
                    const SizedBox(height: 4),
                    Text(names[index], style: const TextStyle(fontSize: 12)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWatchListSection(BuildContext context) {
    final rooms = ['Ashwini', 'Bharani', 'Krittika', 'Rohini'];
    return SafeArea(
      bottom: true,
      child: ListView.builder(
        itemCount: rooms.length,
        padding: EdgeInsets.zero,
        itemBuilder: (context, index) {
          final color =
              Colors.accents[index % Colors.accents.length].withOpacity(0.3);
          return Container(
            height: 100,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              title: Text(rooms[index]),
              trailing: CircleAvatar(
                radius: 12,
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                child: const Text(
                  '0',
                  style: TextStyle(fontSize: 12),
                ),
              ),
              onTap: () => Get.snackbar('Chat Room', 'Open ${rooms[index]}'),
            ),
          );
        },
      ),
    );
  }

  // Deleted account removal feature for now
}
