import 'package:flutter/material.dart';

class SampleSliverAppBar extends StatelessWidget {
  const SampleSliverAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final iconColor = colorScheme.primary.withOpacity(0.6);

    return SliverAppBar(
      pinned: true,
      expandedHeight: 200,
      collapsedHeight: kToolbarHeight,
      automaticallyImplyLeading: false,
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          alignment: Alignment.bottomCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profile')),
                    ),
                    child: const CircleAvatar(radius: 18),
                  ),
                  Container(
                    width: 56,
                    height: 24,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Icon(Icons.all_inclusive, color: iconColor),
                  ),
                  IconButton(
                    icon: Icon(Icons.settings, color: iconColor),
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Settings')),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 48,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 9,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: IconButton(
                      icon: Icon(
                        index.isEven ? Icons.circle : Icons.star,
                        color: iconColor,
                      ),
                      tooltip: 'Details',
                      onPressed: () =>
                          ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Item tapped')),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Material(
                elevation: 1,
                color: colorScheme.surface,
                child: const TabBar(
                  isScrollable: false,
                  tabs: [
                    Tab(text: 'Home'),
                    Tab(text: 'Feed'),
                    Tab(text: 'Events'),
                    Tab(text: 'Preds'),
                    Tab(text: 'Msgs'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
