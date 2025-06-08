import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myapp/controllers/persistent_watchlist_controller.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PersistentWatchlistController controller;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    dotenv.testLoad(fileInput: 'APPWRITE_ENDPOINT=http://localhost');
    controller = PersistentWatchlistController();
    await controller.loadItems();
  });

  test('add item increases list length', () async {
    final item = WatchlistItem(
        id: '1',
        name: 'Test',
        count: 0,
        color: const Color(0xFF000000),
        icon: Icons.star,
        order: 0);
    await controller.addItem(item);
    expect(controller.items.length, 1);
    expect(controller.items.first.order, 0);
  });

  test('remove item updates order', () async {
    final item1 = WatchlistItem(
        id: '1',
        name: 'One',
        count: 0,
        color: const Color(0xFFFFFFFF),
        icon: Icons.star,
        order: 0);
    final item2 = WatchlistItem(
        id: '2',
        name: 'Two',
        count: 0,
        color: const Color(0xFFFFFFFF),
        icon: Icons.star,
        order: 1);
    await controller.addItem(item1);
    await controller.addItem(item2);
    await controller.removeItem('1');
    expect(controller.items.length, 1);
    expect(controller.items.first.id, '2');
    expect(controller.items.first.order, 0);
  });

  test('reorder items updates order', () async {
    final item1 = WatchlistItem(
        id: '1',
        name: 'One',
        count: 0,
        color: const Color(0xFFFFFFFF),
        icon: Icons.star,
        order: 0);
    final item2 = WatchlistItem(
        id: '2',
        name: 'Two',
        count: 0,
        color: const Color(0xFFFFFFFF),
        icon: Icons.star,
        order: 1);
    await controller.addItem(item1);
    await controller.addItem(item2);
    controller.reorderItems(0, 2);
    expect(controller.items.first.id, '2');
    expect(controller.items.first.order, 0);
    expect(controller.items[1].id, '1');
    expect(controller.items[1].order, 1);
  });

  test('items persist locally', () async {
    final item = WatchlistItem(
        id: '3',
        name: 'Persist',
        count: 0,
        color: const Color(0xFFFFFFFF),
        icon: Icons.star,
        order: 0);
    await controller.addItem(item);

    final controller2 = PersistentWatchlistController();
    await controller2.loadItems();
    expect(controller2.items.length, 1);
    expect(controller2.items.first.name, 'Persist');
  });
}
