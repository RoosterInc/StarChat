// lib/widgets/complete_enhanced_watchlist.dart
// All-in-one Enhanced Watchlist Solution

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'package:appwrite/appwrite.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import '../controllers/auth_controller.dart';

// ============================================================================
// DATA MODELS
// ============================================================================

class WatchlistItem {
  final String id;
  final String name;
  final int count;
  final Color color;
  final IconData icon;
  final DateTime createdAt;
  final DateTime updatedAt;

  WatchlistItem({
    required this.id,
    required this.name,
    required this.count,
    required this.color,
    required this.icon,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  WatchlistItem copyWith({
    String? name,
    int? count,
    Color? color,
    IconData? icon,
    DateTime? updatedAt,
  }) {
    return WatchlistItem(
      id: id,
      name: name ?? this.name,
      count: count ?? this.count,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'count': count,
      'colorValue': color.value,
      'iconCodePoint': icon.codePoint,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory WatchlistItem.fromJson(Map<String, dynamic> json) {
    return WatchlistItem(
      id: json['id'],
      name: json['name'],
      count: json['count'],
      color: Color(json['colorValue']),
      icon: IconData(json['iconCodePoint'], fontFamily: 'MaterialIcons'),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.parse(json['createdAt']),
    );
  }
}

// ============================================================================
// CONTROLLER
// ============================================================================

class WatchlistController extends GetxController {
  final RxList<WatchlistItem> _items = <WatchlistItem>[].obs;
  final AuthController _auth = Get.find<AuthController>();
  static const String _watchlistCollectionKey = 'WATCHLIST_ITEMS_COLLECTION_ID';

  final logger = Logger();

  final RxBool _isLoading = false.obs;

  List<WatchlistItem> get items => _items;
  bool get isLoading => _isLoading.value;

  @override
  void onInit() {
    super.onInit();
    _loadItems();
  }

  Future<void> _loadItems() async {
    _isLoading.value = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getStringList('watchlist_items');
      if (cached != null) {
        _items.assignAll(
            cached.map((e) => WatchlistItem.fromJson(jsonDecode(e))).toList());
      }
      await _fetchFromDatabase();
    } catch (e, st) {
      logger.e('Error loading watchlist items', error: e, stackTrace: st);
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> _fetchFromDatabase() async {
    final dbId = dotenv.env['APPWRITE_DATABASE_ID'] ?? 'StarChat_DB';
    final collectionId =
        dotenv.env[_watchlistCollectionKey] ?? 'watchlist_items';
    try {
      final session = await _auth.account.get();
      final uid = session.$id;
      final result = await _auth.databases.listDocuments(
        databaseId: dbId,
        collectionId: collectionId,
        queries: [
          Query.equal('userId', uid),
          Query.orderAsc('order'),
        ],
      );
      if (result.documents.isEmpty && _items.isEmpty) {
        final dummy = [
          WatchlistItem(
              id: ID.unique(),
              name: 'Sample 1',
              count: 0,
              color: Colors.pinkAccent.shade100,
              icon: Icons.star),
          WatchlistItem(
              id: ID.unique(),
              name: 'Sample 2',
              count: 0,
              color: Colors.purpleAccent.shade100,
              icon: Icons.favorite),
        ];
        for (int i = 0; i < dummy.length; i++) {
          final d = dummy[i];
          await _auth.databases.createDocument(
            databaseId: dbId,
            collectionId: collectionId,
            documentId: d.id,
            data: _itemDataForDb(d, uid, order: i, updatedAt: DateTime.now()),
            permissions: [
              Permission.read(Role.user(uid)),
              Permission.update(Role.user(uid)),
              Permission.delete(Role.user(uid)),
            ],
          );
        }
        _items.assignAll(dummy);
      } else {
        _items.assignAll(result.documents.map((doc) {
          final data = doc.data;
          return WatchlistItem(
            id: doc.$id,
            name: data['name'] ?? '',
            count: data['count'] ?? 0,
            color: Color(data['colorValue'] ?? 0xFFEC407A),
            icon: IconData(data['iconCodePoint'] ?? Icons.star.codePoint,
                fontFamily: 'MaterialIcons'),
            createdAt: DateTime.parse(data['createdAt']),
            updatedAt: data['updatedAt'] != null
                ? DateTime.parse(data['updatedAt'])
                : DateTime.parse(data['createdAt']),
          );
        }).toList());
      }
      await _saveItemsToPrefs();
    } catch (e, st) {
      logger.e('Error fetching watchlist from database',
          error: e, stackTrace: st);
    }
  }

  Map<String, dynamic> _itemDataForDb(WatchlistItem item, String uid,
      {int? order, DateTime? updatedAt}) {
    return {
      'userId': uid,
      'name': item.name,
      'count': item.count,
      'colorValue': item.color.value,
      'iconCodePoint': item.icon.codePoint,
      'createdAt': item.createdAt.toIso8601String(),
      'updatedAt': (updatedAt ?? DateTime.now()).toIso8601String(),
      'order': order ?? _items.indexOf(item),
    };
  }

  Future<void> _saveItemsToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = _items.map((e) => jsonEncode(e.toJson())).toList();
      await prefs.setStringList('watchlist_items', data);
    } catch (e, st) {
      logger.e('Error saving watchlist locally', error: e, stackTrace: st);
    }
  }

  // Available colors for new items
  static const List<Color> availableColors = [
    Color(0xFFEC407A),
    Color(0xFFAB47BC),
    Color(0xFF42A5F5),
    Color(0xFF66BB6A),
    Color(0xFFFF7043),
    Color(0xFF26A69A),
    Color(0xFF5C6BC0),
    Color(0xFFFFCA28),
  ];

  // Available icons for new items
  static const List<IconData> availableIcons = [
    Icons.star,
    Icons.favorite,
    Icons.flash_on,
    Icons.brightness_high,
    Icons.nightlight_round,
    Icons.wb_sunny,
    Icons.ac_unit,
    Icons.local_fire_department,
  ];

  Future<void> addItem(WatchlistItem item) async {
    _items.add(item);
    await _saveItemsToPrefs();
    final dbId = dotenv.env['APPWRITE_DATABASE_ID'] ?? 'StarChat_DB';
    final collectionId =
        dotenv.env[_watchlistCollectionKey] ?? 'watchlist_items';
    try {
      final session = await _auth.account.get();
      final uid = session.$id;
      await _auth.databases.createDocument(
        databaseId: dbId,
        collectionId: collectionId,
        documentId: item.id,
        data: _itemDataForDb(item, uid, updatedAt: DateTime.now()),
        permissions: [
          Permission.read(Role.user(uid)),
          Permission.update(Role.user(uid)),
          Permission.delete(Role.user(uid)),
        ],
      );
    } catch (e, st) {
      logger.e('Error adding item to watchlist', error: e, stackTrace: st);
    }
    _showSuccessSnackbar(
      'Added to Watchlist',
      '${item.name} has been added to your watchlist',
      Colors.green,
    );
    HapticFeedback.lightImpact();
  }

  Future<void> removeItem(String id) async {
    final itemIndex = _items.indexWhere((item) => item.id == id);
    if (itemIndex == -1) return;

    final item = _items[itemIndex];
    _items.removeAt(itemIndex);
    await _saveItemsToPrefs();

    final dbId = dotenv.env['APPWRITE_DATABASE_ID'] ?? 'StarChat_DB';
    final collectionId =
        dotenv.env[_watchlistCollectionKey] ?? 'watchlist_items';
    try {
      await _auth.databases.deleteDocument(
        databaseId: dbId,
        collectionId: collectionId,
        documentId: id,
      );
    } catch (e, st) {
      logger.e('Error removing item from watchlist', error: e, stackTrace: st);
    }

    Get.snackbar(
      'Removed from Watchlist',
      '${item.name} has been removed from your watchlist',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 4),
      backgroundColor: Colors.red.shade100,
      colorText: Colors.red.shade800,
      icon: Icon(Icons.delete_outline, color: Colors.red.shade800),
      mainButton: TextButton(
        onPressed: () async {
          _items.insert(itemIndex, item);
          await _saveItemsToPrefs();
          final dbId = dotenv.env['APPWRITE_DATABASE_ID'] ?? 'StarChat_DB';
          final collectionId =
              dotenv.env[_watchlistCollectionKey] ?? 'watchlist_items';
          try {
            final session = await _auth.account.get();
            final uid = session.$id;
            await _auth.databases.createDocument(
              databaseId: dbId,
              collectionId: collectionId,
              documentId: item.id,
              data: _itemDataForDb(item, uid,
                  order: itemIndex, updatedAt: DateTime.now()),
              permissions: [
                Permission.read(Role.user(uid)),
                Permission.update(Role.user(uid)),
                Permission.delete(Role.user(uid)),
              ],
            );
          } catch (e, st) {
            logger.e('Error restoring item to watchlist',
                error: e, stackTrace: st);
          }
          Get.back();
          _showSuccessSnackbar(
              'Restored', '${item.name} has been restored', Colors.blue);
        },
        child:
            const Text('Undo', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
    HapticFeedback.mediumImpact();
  }

  Future<void> updateItemCount(String id, int newCount) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      _items[index] =
          _items[index].copyWith(count: newCount, updatedAt: DateTime.now());
      await _saveItemsToPrefs();
      final dbId = dotenv.env['APPWRITE_DATABASE_ID'] ?? 'StarChat_DB';
      final collectionId =
          dotenv.env[_watchlistCollectionKey] ?? 'watchlist_items';
      try {
        await _auth.databases.updateDocument(
          databaseId: dbId,
          collectionId: collectionId,
          documentId: id,
          data: {
            'count': newCount,
            'updatedAt': DateTime.now().toIso8601String(),
          },
        );
      } catch (e, st) {
        logger.e('Error updating item count', error: e, stackTrace: st);
      }
      HapticFeedback.selectionClick();
    }
  }

  Future<void> updateItem(String id,
      {String? name, int? count, Color? color, IconData? icon}) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      _items[index] = _items[index].copyWith(
        name: name,
        count: count,
        color: color,
        icon: icon,
        updatedAt: DateTime.now(),
      );
      await _saveItemsToPrefs();
      final dbId = dotenv.env['APPWRITE_DATABASE_ID'] ?? 'StarChat_DB';
      final collectionId =
          dotenv.env[_watchlistCollectionKey] ?? 'watchlist_items';
      try {
        final session = await _auth.account.get();
        final uid = session.$id;
        await _auth.databases.updateDocument(
          databaseId: dbId,
          collectionId: collectionId,
          documentId: id,
          data: _itemDataForDb(_items[index], uid,
              order: index, updatedAt: DateTime.now()),
        );
      } catch (e, st) {
        logger.e('Error updating watchlist item', error: e, stackTrace: st);
      }
      _showSuccessSnackbar('Updated', 'Item has been updated', Colors.blue);
    }
  }

  Future<void> reorderItems(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final item = _items.removeAt(oldIndex);
    _items.insert(newIndex, item);
    await _saveItemsToPrefs();
    final dbId = dotenv.env['APPWRITE_DATABASE_ID'] ?? 'StarChat_DB';
    final collectionId =
        dotenv.env[_watchlistCollectionKey] ?? 'watchlist_items';
    try {
      for (int i = 0; i < _items.length; i++) {
        final it = _items[i];
        final updatedItem = it.copyWith(updatedAt: DateTime.now());
        _items[i] = updatedItem;
        await _auth.databases.updateDocument(
          databaseId: dbId,
          collectionId: collectionId,
          documentId: it.id,
          data: {
            'order': i,
            'updatedAt': updatedItem.updatedAt.toIso8601String(),
          },
        );
      }
      await _saveItemsToPrefs();
    } catch (e, st) {
      logger.e('Error reordering watchlist items', error: e, stackTrace: st);
    }
    HapticFeedback.selectionClick();
  }

  Future<void> clearAllItems() async {
    final itemCount = _items.length;
    _items.clear();
    await _saveItemsToPrefs();
    final dbId = dotenv.env['APPWRITE_DATABASE_ID'] ?? 'StarChat_DB';
    final collectionId =
        dotenv.env[_watchlistCollectionKey] ?? 'watchlist_items';
    try {
      final session = await _auth.account.get();
      final uid = session.$id;
      final docs = await _auth.databases.listDocuments(
        databaseId: dbId,
        collectionId: collectionId,
        queries: [Query.equal('userId', uid)],
      );
      for (final doc in docs.documents) {
        await _auth.databases.deleteDocument(
          databaseId: dbId,
          collectionId: collectionId,
          documentId: doc.$id,
        );
      }
    } catch (e, st) {
      logger.e('Error clearing watchlist', error: e, stackTrace: st);
    }
    _showSuccessSnackbar(
        'Cleared', '$itemCount items removed from watchlist', Colors.orange);
  }

  void _showSuccessSnackbar(String title, String message, Color color) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
      backgroundColor: color.withOpacity(0.1),
      colorText: color.withOpacity(0.8),
      icon: Icon(Icons.check_circle_outline, color: color),
    );
  }
}

// ============================================================================
// ANIMATION HELPERS
// ============================================================================

class WatchlistAnimations {
  static Widget buildStaggeredItem({
    required Widget child,
    required int index,
    Duration delay = const Duration(milliseconds: 100),
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * delay.inMilliseconds)),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return Transform.translate(
          offset: Offset(30 * (1 - value), 0),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
    );
  }

  static Widget buildCardEntrance({
    required Widget child,
    required int index,
    Duration? duration,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration ?? Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOutBack,
      builder: (context, value, _) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
    );
  }

  static Widget buildFloatingButton({
    required VoidCallback onPressed,
    required BuildContext context,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: onPressed,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add,
                        color: Theme.of(context).colorScheme.onPrimary,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Add',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ============================================================================
// SWIPEABLE CARD WIDGET
// ============================================================================

class SwipeableWatchlistCard extends StatelessWidget {
  final WatchlistItem item;
  final VoidCallback onRemove;
  final VoidCallback onEdit;
  final VoidCallback onTap;
  final int index;

  const SwipeableWatchlistCard({
    required Key key,
    required this.item,
    required this.onRemove,
    required this.onEdit,
    required this.onTap,
    required this.index,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WatchlistAnimations.buildStaggeredItem(
      index: index,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Dismissible(
          key: key!,
          direction: DismissDirection.horizontal,
          background: _buildSwipeBackground(context, isLeft: true),
          secondaryBackground: _buildSwipeBackground(context, isLeft: false),
          confirmDismiss: (direction) async {
            HapticFeedback.mediumImpact();
            if (direction == DismissDirection.startToEnd) {
              onEdit();
              return false;
            } else {
              return await _showDeleteConfirmation(context);
            }
          },
          onDismissed: (direction) {
            if (direction == DismissDirection.endToStart) {
              onRemove();
            }
          },
          child: _buildCard(context),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            item.color,
            item.color.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: item.color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.drag_indicator,
                    color: Colors.white.withOpacity(0.7),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    item.icon,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Added ${_formatDate(item.createdAt)}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${item.count}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwipeBackground(BuildContext context, {required bool isLeft}) {
    final color = isLeft ? Colors.blue : Colors.red;
    final icon = isLeft ? Icons.edit : Icons.delete;
    final text = isLeft ? 'Edit' : 'Remove';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Align(
        alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
        child: Padding(
          padding: EdgeInsets.only(
            left: isLeft ? 20 : 0,
            right: isLeft ? 0 : 20,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(height: 4),
              Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _showDeleteConfirmation(BuildContext context) async {
    return await Get.dialog<bool>(
          AlertDialog(
            title: const Text('Remove from Watchlist'),
            content: Text(
                'Are you sure you want to remove "${item.name}" from your watchlist?'),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Get.back(result: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Remove'),
              ),
            ],
          ),
        ) ??
        false;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }
}

// ============================================================================
// MAIN WATCHLIST WIDGET
// ============================================================================

class EnhancedWatchlistWidget extends StatelessWidget {
  const EnhancedWatchlistWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(WatchlistController());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Watch List',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            Row(
              children: [
                Obx(() => controller.items.isNotEmpty
                    ? Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          onTap: () => _showClearAllDialog(context, controller),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            child: Icon(
                              Icons.clear_all,
                              size: 20,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink()),
                WatchlistAnimations.buildFloatingButton(
                  onPressed: () => _showAddItemDialog(context, controller),
                  context: context,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Obx(() {
            if (controller.items.isEmpty) {
              return _buildEmptyState(context, controller);
            }

            return ReorderableListView.builder(
              onReorder: controller.reorderItems,
              itemCount: controller.items.length,
              padding: EdgeInsets.zero,
              proxyDecorator: (child, index, animation) {
                return AnimatedBuilder(
                  animation: animation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 1.05,
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: child,
                      ),
                    );
                  },
                  child: child,
                );
              },
              itemBuilder: (context, index) {
                final item = controller.items[index];
                return SwipeableWatchlistCard(
                  key: ValueKey(item.id),
                  item: item,
                  index: index,
                  onRemove: () => controller.removeItem(item.id),
                  onEdit: () => _showEditItemDialog(context, controller, item),
                  onTap: () => _showItemDetails(context, item),
                );
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildEmptyState(
      BuildContext context, WatchlistController controller) {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOut,
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 30 * (1 - value)),
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom + 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceVariant
                            .withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.playlist_add,
                        size: 48,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Your watchlist is empty',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add items to keep track of your favorites',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                                .withOpacity(0.7),
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => _showAddItemDialog(context, controller),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Your First Item'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddItemDialog(
      BuildContext context, WatchlistController controller) {
    final nameController = TextEditingController();
    final countController = TextEditingController(text: '0');
    Color selectedColor = WatchlistController.availableColors.first;
    IconData selectedIcon = WatchlistController.availableIcons.first;

    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Add to Watchlist'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.label_outline),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: countController,
                    decoration: const InputDecoration(
                      labelText: 'Initial Count',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.numbers),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  const Text('Choose Color:',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: WatchlistController.availableColors.map((color) {
                      final isSelected = color == selectedColor;
                      return GestureDetector(
                        onTap: () {
                          setState(() => selectedColor = color);
                          HapticFeedback.selectionClick();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(color: Colors.black, width: 3)
                                : Border.all(
                                    color: Colors.grey.shade300, width: 1),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                        color: color.withOpacity(0.5),
                                        blurRadius: 8)
                                  ]
                                : null,
                          ),
                          child: isSelected
                              ? const Icon(Icons.check,
                                  color: Colors.white, size: 20)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text('Choose Icon:',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: WatchlistController.availableIcons.map((icon) {
                      final isSelected = icon == selectedIcon;
                      return GestureDetector(
                        onTap: () {
                          setState(() => selectedIcon = icon);
                          HapticFeedback.selectionClick();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.surfaceVariant,
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    width: 2)
                                : null,
                          ),
                          child: Icon(
                            icon,
                            color: isSelected
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final name = nameController.text.trim();
                  final count = int.tryParse(countController.text.trim()) ?? 0;

                  if (name.isNotEmpty) {
                    final newItem = WatchlistItem(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: name,
                      count: count,
                      color: selectedColor,
                      icon: selectedIcon,
                    );
                    controller.addItem(newItem);
                    Get.back();
                  }
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditItemDialog(BuildContext context, WatchlistController controller,
      WatchlistItem item) {
    final nameController = TextEditingController(text: item.name);
    final countController = TextEditingController(text: item.count.toString());
    Color selectedColor = item.color;
    IconData selectedIcon = item.icon;

    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Edit ${item.name}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: countController,
                    decoration: const InputDecoration(
                      labelText: 'Count',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  const Text('Color:',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: WatchlistController.availableColors.map((color) {
                      final isSelected = color == selectedColor;
                      return GestureDetector(
                        onTap: () => setState(() => selectedColor = color),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(color: Colors.black, width: 2)
                                : null,
                          ),
                          child: isSelected
                              ? const Icon(Icons.check, color: Colors.white)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text('Icon:',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: WatchlistController.availableIcons.map((icon) {
                      final isSelected = icon == selectedIcon;
                      return GestureDetector(
                        onTap: () => setState(() => selectedIcon = icon),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.surfaceVariant,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            icon,
                            color: isSelected
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final name = nameController.text.trim();
                  final count = int.tryParse(countController.text) ?? 0;

                  if (name.isNotEmpty) {
                    controller.updateItem(
                      item.id,
                      name: name,
                      count: count,
                      color: selectedColor,
                      icon: selectedIcon,
                    );
                    Get.back();
                  }
                },
                child: const Text('Update'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showItemDetails(BuildContext context, WatchlistItem item) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [item.color, item.color.withOpacity(0.8)],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(item.icon, size: 32, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              item.name,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Count: ${item.count}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Added ${item.createdAt.day}/${item.createdAt.month}/${item.createdAt.year}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Get.back();
                      _showEditItemDialog(
                          context, Get.find<WatchlistController>(), item);
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Get.back(),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showClearAllDialog(
      BuildContext context, WatchlistController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('Clear All Items'),
        content: const Text(
            'Are you sure you want to remove all items from your watchlist? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.clearAllItems();
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}
