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

    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Obx(
              () => UserAccountsDrawerHeader(
                currentAccountPicture: CircleAvatar(
                  backgroundImage:
                      authController.profilePictureUrl.value.isNotEmpty
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
          ],
        ),
      ),
      body: CustomScrollView(
        slivers: [
          const SampleSliverAppBar(),
          SliverFillRemaining(
            hasScrollBody: false,
            child: ResponsiveLayout(
              mobile: (_) => _buildContent(
                  context, MediaQuery.of(context).size.width * 0.9),
              tablet: (_) => _buildContent(context, 500),
              desktop: (_) => _buildContent(context, 600),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: 'Settings'),
        ],
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Obx(() => Text(
                  'signed_in_as'
                      .trParams({'username': authController.username.value}),
                  style: const TextStyle(fontSize: 24),
                  textAlign: TextAlign.center,
                )),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                Get.closeAllSnackbars();
                await Get.find<AuthController>().logout();
              },
              child: Text('logout'.tr),
            ),
          ],
        ),
      ),
    );
  }

  // Deleted account removal feature for now
}
