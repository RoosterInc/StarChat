import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:appwrite/appwrite.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logger/logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Watchlist item model with ordering information.
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
    required this.order,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.needsSync = false,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  WatchlistItem copyWith({
    String? name,
    int? count,
    Color? color,
    IconData? icon,
    int? order,
    bool? needsSync,
  }) {
    return WatchlistItem(
      id: id,
      name: name ?? this.name,
      count: count ?? this.count,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      order: order ?? this.order,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      needsSync: needsSync ?? this.needsSync,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'count': count,
      'color': color.value,
      'icon': icon.codePoint,
      'iconFont': icon.fontFamily,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'order': order,
      'needsSync': needsSync,
    };
  }

  factory WatchlistItem.fromJson(Map<String, dynamic> json) {
    return WatchlistItem(
      id: json['id'],
      name: json['name'],
      count: json['count'],
      color: Color(json['color']),
      icon: IconData(json['icon'],
          fontFamily: json['iconFont'] ?? 'MaterialIcons'),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      order: json['order'],
      needsSync: json['needsSync'] ?? false,
    );
  }

  Map<String, dynamic> toAppwriteDoc(String userId) {
    return {
      'userId': userId,
      'name': name,
      'count': count,
      'color': color.value,
      'iconCodePoint': icon.codePoint,
      'iconFontFamily': icon.fontFamily ?? 'MaterialIcons',
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'order': order,
    };
  }

  factory WatchlistItem.fromAppwriteDoc(Map<String, dynamic> data, String id) {
    return WatchlistItem(
      id: id,
      name: data['name'],
      count: data['count'],
      color: Color(data['color']),
      icon: IconData(data['iconCodePoint'],
          fontFamily: data['iconFontFamily'] ?? 'MaterialIcons'),
      createdAt: DateTime.parse(data['createdAt']),
      updatedAt: DateTime.parse(data['updatedAt']),
      order: data['order'],
      needsSync: false,
    );
  }
}

/// Basic design constants reused from the enhanced watchlist.
class WatchlistDesign {
  static const double radius = 16.0;
  static const double spacing = 12.0;
}

/// Controller handling persistence and sync.
class PersistentWatchlistController extends GetxController {
  final _logger = Logger();
  final RxList<WatchlistItem> items = <WatchlistItem>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isOnline = true.obs;

  static const _storageKey = 'watchlist_items_persistent';
  final String _databaseId =
      dotenv.env['APPWRITE_DATABASE_ID'] ?? 'StarChat_DB';
  final String _collectionId = 'watchlist_items';
  late Client _client;
  late Databases _db;
  late Account _account;

  @override
  Future<void> onInit() async {
    super.onInit();
    _client = Client()
      ..setEndpoint(dotenv.env['APPWRITE_ENDPOINT'] ?? '')
      ..setProject(dotenv.env['APPWRITE_PROJECT_ID'] ?? '');
    _db = Databases(_client);
    _account = Account(_client);

    await _loadLocal();
    await _initConnectivity();
    if (isOnline.value) {
      await syncFromCloud();
    }
    isLoading.value = false;
  }

  Future<void> _initConnectivity() async {
    final c = Connectivity();
    isOnline.value = await c.checkConnectivity() != ConnectivityResult.none;
    c.onConnectivityChanged.listen((r) {
      final nowOnline = r != ConnectivityResult.none;
      if (!isOnline.value && nowOnline) {
        syncToCloud();
      }
      isOnline.value = nowOnline;
    });
  }

  Future<void> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_storageKey);
    if (str == null) return;
    final data = jsonDecode(str) as List;
    items.assignAll(data.map((e) => WatchlistItem.fromJson(e)));
  }

  Future<void> _saveLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(items.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, data);
  }

  Future<String?> _userId() async {
    try {
      final s = await _account.get();
      return s.$id;
    } catch (_) {
      return null;
    }
  }

  Future<void> syncToCloud() async {
    final uid = await _userId();
    if (uid == null) return;
    for (final item in items) {
      try {
        await _db.updateDocument(
          databaseId: _databaseId,
          collectionId: _collectionId,
          documentId: item.id,
          data: item.toAppwriteDoc(uid),
        );
      } catch (_) {
        try {
          await _db.createDocument(
            databaseId: _databaseId,
            collectionId: _collectionId,
            documentId: item.id,
            data: item.toAppwriteDoc(uid),
          );
        } catch (e) {
          _logger.w('cloud sync failed: $e');
        }
      }
    }
  }

  Future<void> syncFromCloud() async {
    final uid = await _userId();
    if (uid == null) return;
    try {
      final res = await _db.listDocuments(
        databaseId: _databaseId,
        collectionId: _collectionId,
        queries: [Query.equal('userId', uid), Query.orderAsc('order')],
      );
      final cloud = res.documents
          .map((d) => WatchlistItem.fromAppwriteDoc(d.data, d.$id))
          .toList();
      items.assignAll(cloud);
      await _saveLocal();
    } catch (e) {
      _logger.w('cloud fetch failed: $e');
    }
  }

  Future<void> addItem(WatchlistItem item) async {
    final maxOrder = items.isEmpty
        ? -1
        : items.map((e) => e.order).reduce((a, b) => a > b ? a : b);
    items.add(item.copyWith(order: maxOrder + 1, needsSync: true));
    await _saveLocal();
    if (isOnline.value) syncToCloud();
  }

  Future<void> updateItem(String id,
      {String? name, int? count, Color? color, IconData? icon}) async {
    final idx = items.indexWhere((e) => e.id == id);
    if (idx == -1) return;
    items[idx] = items[idx].copyWith(
      name: name,
      count: count,
      color: color,
      icon: icon,
      needsSync: true,
    );
    await _saveLocal();
    if (isOnline.value) syncToCloud();
  }

  Future<void> removeItem(String id) async {
    items.removeWhere((e) => e.id == id);
    await _saveLocal();
    if (isOnline.value) {
      final uid = await _userId();
      if (uid != null) {
        try {
          await _db.deleteDocument(
            databaseId: _databaseId,
            collectionId: _collectionId,
            documentId: id,
          );
        } catch (_) {}
      }
    }
  }

  void reorderItems(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);
    for (var i = 0; i < items.length; i++) {
      items[i] = items[i].copyWith(order: i, needsSync: true);
    }
    _saveLocal();
    if (isOnline.value) syncToCloud();
  }
}

/// Main widget using the existing design from [EnhancedWatchlistWidget].
class CompletePersistentWatchlistWidget extends StatelessWidget {
  const CompletePersistentWatchlistWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PersistentWatchlistController());
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      return _buildList(context, controller);
    });
  }

  Widget _buildList(BuildContext context, PersistentWatchlistController c) {
    if (c.items.isEmpty) {
      return const Center(child: Text('No items'));
    }
    return ReorderableListView.builder(
      onReorder: c.reorderItems,
      itemCount: c.items.length,
      itemBuilder: (ctx, i) {
        final item = c.items[i];
        return ListTile(
          key: ValueKey(item.id),
          tileColor: item.color,
          title: Text(item.name, style: const TextStyle(color: Colors.white)),
          leading: Icon(item.icon, color: Colors.white),
          trailing: Text('${item.count}',
              style: const TextStyle(color: Colors.white)),
          onTap: () => _showEdit(ctx, c, item),
        );
      },
    );
  }

  void _showEdit(BuildContext context, PersistentWatchlistController c,
      WatchlistItem item) {
    final nameCtrl = TextEditingController(text: item.name);
    Get.dialog(AlertDialog(
      title: const Text('Edit item'),
      content: TextField(controller: nameCtrl),
      actions: [
        TextButton(onPressed: Get.back, child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            c.updateItem(item.id, name: nameCtrl.text);
            Get.back();
          },
          child: const Text('Save'),
        ),
      ],
    ));
  }
}
