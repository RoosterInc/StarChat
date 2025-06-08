import 'package:flutter/material.dart';
import 'responsive_layout.dart';

class AdaptiveNavigation extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onDestinationSelected;
  final Widget body;

  const AdaptiveNavigation({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.body,
  });

  static const destinations = [
    NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home),
        label: 'Home'),
    NavigationDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard),
        label: 'Dashboard'),
    NavigationDestination(
        icon: Icon(Icons.search_outlined),
        selectedIcon: Icon(Icons.search),
        label: 'Search'),
    NavigationDestination(
        icon: Icon(Icons.favorite_outline),
        selectedIcon: Icon(Icons.favorite),
        label: 'Match'),
    NavigationDestination(
        icon: Icon(Icons.notifications_none),
        selectedIcon: Icon(Icons.notifications),
        label: 'Notifications'),
    NavigationDestination(
        icon: Icon(Icons.storefront_outlined),
        selectedIcon: Icon(Icons.storefront),
        label: 'Marketplace'),
  ];

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: (_) => _buildMobileLayout(context),
      tablet: (_) => _buildTabletLayout(context),
      desktop: (_) => _buildDesktopLayout(context),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: destinations,
        animationDuration: const Duration(milliseconds: 300),
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            extended: MediaQuery.of(context).size.width > 800,
            minWidth: 72,
            minExtendedWidth: 200,
            destinations: destinations
                .map((dest) => NavigationRailDestination(
                      icon: dest.icon,
                      selectedIcon: dest.selectedIcon,
                      label: Text(dest.label),
                    ))
                .toList(),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: body),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 280,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                  right: BorderSide(color: Theme.of(context).dividerColor)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Icon(Icons.star,
                          size: 32,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 12),
                      Text('StarChat',
                          style: Theme.of(context).textTheme.headlineSmall),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    itemCount: destinations.length,
                    itemBuilder: (context, index) {
                      final dest = destinations[index];
                      final isSelected = index == selectedIndex;
                      return Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        child: ListTile(
                          leading: isSelected ? dest.selectedIcon : dest.icon,
                          title: Text(dest.label),
                          selected: isSelected,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          onTap: () => onDestinationSelected(index),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}
