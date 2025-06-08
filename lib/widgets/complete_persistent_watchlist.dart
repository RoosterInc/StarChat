import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/persistent_watchlist_controller.dart';
class CompletePersistentWatchlistWidget extends StatelessWidget {
  const CompletePersistentWatchlistWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(PersistentWatchlistController());
    return Column(children: [
      Expanded(
          child: Obx(() => c.items.isEmpty
              ? const Center(child: Text('No items'))
              : ReorderableListView.builder(
                  onReorder: c.reorderItems,
                  itemCount: c.items.length,
                  itemBuilder: (context, i) {
                    final it = c.items[i];
                    return ListTile(
                      key: ValueKey(it.id),
                      leading: CircleAvatar(
                          backgroundColor: it.color,
                          child: Icon(it.icon, color: Colors.white)),
                      title: Text(it.name),
                      trailing: Text('${it.count}'),
                    );
                  },
                ))),
      Padding(
        padding: const EdgeInsets.all(8),
        child: ElevatedButton(
            onPressed: () {
              final n = WatchlistItem(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: 'Item ${c.items.length + 1}',
                  count: 0,
                  color: Colors.blue,
                  icon: Icons.star,
                  order: 0);
              c.addItem(n);
            },
            child: const Text('Add Item')),
      )
    ]);
  }
}
