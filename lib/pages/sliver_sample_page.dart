import 'package:flutter/material.dart';
import '../widgets/sample_sliver_app_bar.dart';

class SliverSamplePage extends StatelessWidget {
  const SliverSamplePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        drawer: const Drawer(child: Center(child: Text('Menu'))),
        body: CustomScrollView(
          slivers: [
            const SampleSliverAppBar(),
            SliverFillRemaining(
              child: Container(
                color: Theme.of(context).colorScheme.secondaryContainer,
                alignment: Alignment.center,
                child: const Text('Scroll to see sticky header'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
