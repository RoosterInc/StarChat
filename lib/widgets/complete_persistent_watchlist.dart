import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:appwrite/appwrite.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Simple data model for a watchlist item.
class WatchlistItem {
  final String id;
  final String name;
  final int count;
  final Color color;
  final IconData icon;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int order;
  final bool needsSync;

  WatchlistItem({
    required this.id,
    required this.name,
    required this.count,
    required this.color,
    required this.icon,
    DateTime? createdAt,
    DateTime? updatedAt,
    required this.order,
    this.needsSync = false,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  WatchlistItem copyWith({
    String? name,
    int? count,
    Color? color,
    IconData? icon,
    DateTime? updatedAt,
    int? order,
    bool? needsSync,
  }) {
    return WatchlistItem(
      id: id,
      name: name ?? this.name,
      count: count ?? this.count,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      order: order ?? this.order,
      needsSync: needsSync ?? this.needsSync,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'count': count,
        'colorValue': color.value,
        'iconCodePoint': icon.codePoint,
        'iconFontFamily': icon.fontFamily,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'order': order,
        'needsSync': needsSync,
      };

  factory WatchlistItem.fromJson(Map<String, dynamic> json) {
    return WatchlistItem(
      id: json['id'],
      name: json['name'],
      count: json['count'] ?? 0,
      color: Color(json['colorValue']),
      icon: IconData(json['iconCodePoint'],
          fontFamily: json['iconFontFamily'] ?? 'MaterialIcons'),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      order: json['order'] ?? 0,
      needsSync: json['needsSync'] ?? false,
    );
  }

  Map<String, dynamic> toDoc(String userId) => {
        'userId': userId,
        'name': name,
        'count': count,
        'colorValue': color.value,
        'iconCodePoint': icon.codePoint,
        'iconFontFamily': icon.fontFamily ?? 'MaterialIcons',
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'order': order,
      };

  factory WatchlistItem.fromDoc(String id, Map<String, dynamic> data) {
    return WatchlistItem(
      id: id,
      name: data['name'],
      count: data['count'] ?? 0,
      color: Color(data['colorValue']),
      icon: IconData(data['iconCodePoint'],
          fontFamily: data['iconFontFamily'] ?? 'MaterialIcons'),
      createdAt: DateTime.parse(data['createdAt']),
      updatedAt: DateTime.parse(data['updatedAt']),
      order: data['order'] ?? 0,
    );
  }
}
class PersistentWatchlistController extends GetxController {
  final _items = <WatchlistItem>[].obs;
  final _online = false.obs;
  final _syncing = false.obs;

  List<WatchlistItem> get items => _items;
  bool get isOnline => _online.value;
  bool get isSyncing => _syncing.value;

  late Client _client;
  late Databases _db;
  late Account _account;

  static const _storageKey = 'watchlist_items';
  final String _databaseId = dotenv.env['APPWRITE_DATABASE_ID'] ?? '';
  final String _collectionId =
      dotenv.env['WATCHLIST_COLLECTION_ID'] ?? 'watchlist_items';
  @override
  Future<void> onInit() async {
    super.onInit();
    _client = Client()
      ..setEndpoint(dotenv.env['APPWRITE_ENDPOINT'] ?? '')
      ..setProject(dotenv.env['APPWRITE_PROJECT_ID'] ?? '');
    _db = Databases(_client);
    _account = Account(_client);
    final conn = Connectivity();
    _online.value = await conn.checkConnectivity() != ConnectivityResult.none;
    conn.onConnectivityChanged.listen((r) {
      final nowOnline = r != ConnectivityResult.none;
      if (!_online.value && nowOnline) {
        _syncPending();
      }
      _online.value = nowOnline;
    });
    await loadItems();
  }
  Future<void> _saveLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _storageKey, jsonEncode(_items.map((e) => e.toJson()).toList()));
  }

  Future<List<WatchlistItem>> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_storageKey);
    if (str == null) return [];
    final data = jsonDecode(str) as List;
    return data
        .map((e) => WatchlistItem.fromJson(e))
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }
  Future<String?> _uid() async {
    try {
      final u = await _account.get();
      return u.$id;
    } catch (_) {
      return null;
    }
  }

  Future<void> _syncItem(WatchlistItem item) async {
    final uid = await _uid();
    if (uid == null) return;
    try {
      await _db.updateDocument(
          databaseId: _databaseId,
          collectionId: _collectionId,
          documentId: item.id,
          data: item.toDoc(uid));
    } catch (_) {
      await _db.createDocument(
        databaseId: _databaseId,
        collectionId: _collectionId,
        documentId: item.id,
        data: item.toDoc(uid),
        permissions: [
          Permission.read(Role.user(uid)),
          Permission.update(Role.user(uid)),
          Permission.delete(Role.user(uid)),
        ],
      );
    }
  }
  Future<void> _syncFromCloud() async {
    final uid = await _uid();
    if (uid == null) return;
    final docs = await _db.listDocuments(
      databaseId: _databaseId,
      collectionId: _collectionId,
      queries: [Query.equal('userId', uid), Query.orderAsc('order')],
    );
    final cloud = docs.documents
        .map((d) => WatchlistItem.fromDoc(d.$id, d.data))
        .toList();
    _items.assignAll(_merge(_items, cloud));
    await _saveLocal();
  }

  List<WatchlistItem> _merge(
      List<WatchlistItem> local, List<WatchlistItem> cloud) {
    final map = {for (var c in cloud) c.id: c};
    for (var l in local) {
      final e = map[l.id];
      if (e == null || l.updatedAt.isAfter(e.updatedAt)) {
        map[l.id] = l;
      }
    }
    final list = map.values.toList();
    list.sort((a, b) => a.order.compareTo(b.order));
    return list;
  }
  Future<void> _syncPending() async {
    if (!_online.value) return;
    _syncing.value = true;
    for (final i in _items.where((e) => e.needsSync)) {
      await _syncItem(i);
      final idx = _items.indexWhere((e) => e.id == i.id);
      if (idx != -1) _items[idx] = i.copyWith(needsSync: false);
    }
    await _syncFromCloud();
    await _saveLocal();
    _syncing.value = false;
  }

  Future<void> loadItems() async {
    final local = await _loadLocal();
    _items.assignAll(local);
    if (_online.value) await _syncFromCloud();
  }
  Future<void> addItem(WatchlistItem item) async {
    final order =
        _items.isEmpty ? 0 : _items.map((e) => e.order).reduce((a, b) => a > b ? a : b) + 1;
    final n = item.copyWith(order: order, needsSync: true);
    _items.add(n);
    await _saveLocal();
    if (_online.value) await _syncItem(n);
  }

  Future<void> updateItem(String id,
      {String? name, int? count, Color? color, IconData? icon}) async {
    final idx = _items.indexWhere((e) => e.id == id);
    if (idx == -1) return;
    final u = _items[idx]
        .copyWith(name: name, count: count, color: color, icon: icon, needsSync: true);
    _items[idx] = u;
    await _saveLocal();
    if (_online.value) await _syncItem(u);
  }
  Future<void> removeItem(String id) async {
    final idx = _items.indexWhere((e) => e.id == id);
    if (idx == -1) return;
    final rem = _items.removeAt(idx);
    for (int i = 0; i < _items.length; i++) {
      _items[i] = _items[i].copyWith(order: i, needsSync: true);
    }
    await _saveLocal();
    if (_online.value) {
      final uid = await _uid();
      if (uid != null) {
        try {
          await _db.deleteDocument(
              databaseId: _databaseId,
              collectionId: _collectionId,
              documentId: rem.id);
        } catch (_) {}
      }
    }
  }

  void reorderItems(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    final item = _items.removeAt(oldIndex);
    _items.insert(newIndex, item);
    for (int i = 0; i < _items.length; i++) {
      _items[i] = _items[i].copyWith(order: i, needsSync: true);
    }
    _saveLocal();
    if (_online.value) _syncPending();
  }
}
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
