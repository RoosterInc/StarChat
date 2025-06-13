import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:myapp/design_system/modern_ui_system.dart';

class _TestApp extends StatefulWidget {
  const _TestApp(this.destinations);

  final List<NavigationDestination> destinations;

  @override
  State<_TestApp> createState() => _TestAppState();
}

class _TestAppState extends State<_TestApp> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: AdaptiveNavigation(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: widget.destinations,
        body: const SizedBox.shrink(),
      ),
    );
  }
}

void main() {
  testWidgets('Navigation labels visible only for selected destination', (tester) async {
    const destinations = <NavigationDestination>[
      NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home),
        label: 'Home',
      ),
      NavigationDestination(
        icon: Icon(Icons.search_outlined),
        selectedIcon: Icon(Icons.search),
        label: 'Search',
      ),
    ];
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.resetView);

    await tester.pumpWidget(const _TestApp(destinations));

    final NavigationBar navBar =
        tester.widget(find.byType(NavigationBar));
    expect(navBar.labelBehavior,
        NavigationDestinationLabelBehavior.onlyShowSelected);
  });
}
