// lib/widgets/complete_enhanced_watchlist.dart
// Fixed Enhanced Watchlist Solution

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'package:appwrite/appwrite.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../design_system/modern_ui_system.dart';
import '../utils/logger.dart';
import '../controllers/auth_controller.dart';
import '../utils/parsing_utils.dart';

// Helper function to determine if we should use light or dark text
Color _getAdaptiveTextColor(Color backgroundColor) {
  // Calculate the perceptive luminance
  double luminance = backgroundColor.computeLuminance();

  // Use white text for dark backgrounds, dark text for light backgrounds
  return luminance > 0.5 ? Colors.black87 : Colors.white;
}

Color _lightenColor(Color color, [double amount = 0.3]) {
  assert(amount >= 0 && amount <= 1);
  return Color.lerp(color, Colors.white, amount)!;
}

// ============================================================================
// DATA MODELS
// ============================================================================

class RashiOption {
  final String id;
  final String name;
  final String rashiId;
  final String symbol;

  RashiOption({
    required this.id,
    required this.name,
    required this.rashiId,
    required this.symbol,
  });

  factory RashiOption.fromJson(Map<String, dynamic> json) {
    return RashiOption(
      id: json['\$id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      rashiId: json['rashi_id'] ?? '',
      symbol: json['symbol'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'rashi_id': rashiId,
      'symbol': symbol,
    };
  }

  @override
  String toString() =>
      'RashiOption(id: $id, name: $name, rashiId: $rashiId, symbol: $symbol)';
}

class NakshatraOption {
  final String id;
  final String name;
  final String nakshatraId;
  final String rashiId; // Single rashi_id, not a list
  final String symbol;

  NakshatraOption({
    required this.id,
    required this.name,
    required this.nakshatraId,
    required this.rashiId,
    required this.symbol,
  });

  factory NakshatraOption.fromJson(Map<String, dynamic> json) {
    return NakshatraOption(
      id: json['\$id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      nakshatraId: json['nakshatra_id'] ?? '',
      rashiId: json['rashi_id'] ?? '', // Single string, not array
      symbol: json['symbol'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nakshatra_id': nakshatraId,
      'rashi_id': rashiId,
      'symbol': symbol,
    };
  }

  @override
  String toString() =>
      'NakshatraOption(id: $id, name: $name, nakshatraId: $nakshatraId, rashiId: $rashiId, symbol: $symbol)';
}

class WatchlistItem {
  final String id;
  final String name;
  final int count;
  final Color color;
  final String? rashiId;
  final String? nakshatraId;
  final String? combinationKey;
  final String? chatRoomId;
  final String watchlistKey;
  final DateTime createdAt;
  final DateTime updatedAt;

  WatchlistItem({
    required this.id,
    required this.name,
    required this.count,
    required this.color,
    this.rashiId,
    this.nakshatraId,
    this.combinationKey,
    this.chatRoomId,
    this.watchlistKey = '',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  WatchlistItem copyWith({
    String? name,
    int? count,
    Color? color,
    String? rashiId,
    String? nakshatraId,
    String? combinationKey,
    String? chatRoomId,
    String? watchlistKey,
    DateTime? updatedAt,
  }) {
    return WatchlistItem(
      id: id,
      name: name ?? this.name,
      count: count ?? this.count,
      color: color ?? this.color,
      rashiId: rashiId ?? this.rashiId,
      nakshatraId: nakshatraId ?? this.nakshatraId,
      combinationKey: combinationKey ?? this.combinationKey,
      chatRoomId: chatRoomId ?? this.chatRoomId,
      watchlistKey: watchlistKey ?? this.watchlistKey,
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
      'rashiId': rashiId,
      'nakshatraId': nakshatraId,
      'combinationKey': combinationKey,
      'chatRoomId': chatRoomId,
      'watchlistKey': watchlistKey,
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
      rashiId: json['rashiId'],
      nakshatraId: json['nakshatraId'],
      combinationKey: json['combinationKey'],
      chatRoomId: json['chatRoomId'],
      watchlistKey: json['watchlistKey'] ?? '',
      createdAt: ParsingUtils.parseDateTime(json['createdAt']),
      updatedAt: json['updatedAt'] != null
          ? ParsingUtils.parseDateTime(json['updatedAt'])
          : ParsingUtils.parseDateTime(json['createdAt']),
    );
  }
}

// ============================================================================
// CONTROLLER
// ============================================================================

class WatchlistController extends GetxController {
  WatchlistController({this.testing = false});
  final bool testing;

  final RxList<WatchlistItem> _items = <WatchlistItem>[].obs;
  final RxList<RashiOption> _rashiOptions = <RashiOption>[].obs;
  final RxList<NakshatraOption> _nakshatraOptions = <NakshatraOption>[].obs;
  final RxBool _isLoadingOptions = false.obs;
  final RxBool _isLoading = false.obs;
  final AuthController _auth = Get.find<AuthController>();

  static const String _watchlistCollectionKey = 'WATCHLIST_ITEMS_COLLECTION_ID';
  static const String _rashiCacheKey = 'cached_rashi_options_v1';
  static const String _nakshatraCacheKey = 'cached_nakshatra_options_v1';
  static const String _masterDataVersionKey = 'master_data_version_v1';

  List<WatchlistItem> get items => _items;
  List<RashiOption> get rashiOptions => _rashiOptions;
  List<NakshatraOption> get nakshatraOptions => _nakshatraOptions;
  bool get isLoading => _isLoading.value;
  bool get isLoadingOptions => _isLoadingOptions.value;

  Future<String> _prefsKey() async {
    String? uid = _auth.userId;
    if (uid == null) {
      try {
        final session = await _auth.account.get();
        uid = session.$id;
      } catch (_) {}
    }
    return 'watchlist_items_${uid ?? 'guest'}';
  }

  @override
  void onInit() {
    super.onInit();
    _loadItems();
    _loadRashiNakshatraOptions();
  }

  Future<void> _loadRashiNakshatraOptions() async {
    if (testing) {
      _createMockData();
      return;
    }

    _isLoadingOptions.value = true;
    try {
      // Try to load from cache first
      final prefs = await SharedPreferences.getInstance();
      final cachedRashi = prefs.getStringList(_rashiCacheKey);
      final cachedNakshatra = prefs.getStringList(_nakshatraCacheKey);

      if (cachedRashi != null && cachedNakshatra != null) {
        logger.i('Loading Rashi/Nakshatra data from cache');
        _rashiOptions.assignAll(
          cachedRashi.map((e) => RashiOption.fromJson(jsonDecode(e))).toList(),
        );
        _nakshatraOptions.assignAll(
          cachedNakshatra
              .map((e) => NakshatraOption.fromJson(jsonDecode(e)))
              .toList(),
        );
      }

      // Always try to fetch fresh data from database
      await _fetchMasterDataFromDatabase();
    } catch (e, st) {
      logger.e('Error loading options', error: e, stackTrace: st);
      if (_rashiOptions.isEmpty || _nakshatraOptions.isEmpty) {
        _createMockData(); // Fallback to mock data
      }
    } finally {
      _isLoadingOptions.value = false;
    }
  }

  Future<void> _fetchMasterDataFromDatabase() async {
    final dbId = dotenv.env['APPWRITE_DATABASE_ID'] ?? 'StarChat_DB';

    try {
      // Fetch Rashi data
      final rashiResult = await _auth.databases.listDocuments(
        databaseId: dbId,
        collectionId: 'rasi_master',
        queries: [Query.orderAsc('name'), Query.limit(50)],
      );

      final rashiList = rashiResult.documents
          .map((e) => RashiOption.fromJson(e.data))
          .toList();
      if (rashiList.isNotEmpty) {
        _rashiOptions.assignAll(rashiList);
        logger.i('Loaded ${rashiList.length} Rashi options from database');
      }

      // Fetch Nakshatra data
      final nakshatraResult = await _auth.databases.listDocuments(
        databaseId: dbId,
        collectionId: 'nakshatra_master',
        queries: [Query.orderAsc('name'), Query.limit(100)],
      );

      final nakshatraList = nakshatraResult.documents
          .map((e) => NakshatraOption.fromJson(e.data))
          .toList();
      if (nakshatraList.isNotEmpty) {
        _nakshatraOptions.assignAll(nakshatraList);
        logger.i(
            'Loaded ${nakshatraList.length} Nakshatra options from database');
      }

      // Cache the fresh data
      await _cacheMasterData();
    } catch (e, st) {
      logger.e('Error fetching master data from database',
          error: e, stackTrace: st);
    }
  }

  Future<void> _cacheMasterData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final rashiJson =
          _rashiOptions.map((e) => jsonEncode(e.toJson())).toList();
      final nakshatraJson =
          _nakshatraOptions.map((e) => jsonEncode(e.toJson())).toList();

      await prefs.setStringList(_rashiCacheKey, rashiJson);
      await prefs.setStringList(_nakshatraCacheKey, nakshatraJson);
      await prefs.setString(
          _masterDataVersionKey, DateTime.now().toIso8601String());

      logger.i('Cached master data successfully');
    } catch (e, st) {
      logger.e('Error caching master data', error: e, stackTrace: st);
    }
  }

  void _createMockData() {
    // Mock data as fallback
    _rashiOptions.assignAll([
      RashiOption(id: '1', name: 'Aries', rashiId: 'r1', symbol: '♈'),
      RashiOption(id: '2', name: 'Taurus', rashiId: 'r2', symbol: '♉'),
      RashiOption(id: '3', name: 'Gemini', rashiId: 'r3', symbol: '♊'),
      RashiOption(id: '4', name: 'Cancer', rashiId: 'r4', symbol: '♋'),
      RashiOption(id: '5', name: 'Leo', rashiId: 'r5', symbol: '♌'),
      RashiOption(id: '6', name: 'Virgo', rashiId: 'r6', symbol: '♍'),
    ]);

    _nakshatraOptions.assignAll([
      NakshatraOption(
          id: '1',
          name: 'Ashwini',
          nakshatraId: 'n1',
          rashiId: 'r1',
          symbol: '★'),
      NakshatraOption(
          id: '2',
          name: 'Bharani',
          nakshatraId: 'n2',
          rashiId: 'r1',
          symbol: '⚘'),
      NakshatraOption(
          id: '3',
          name: 'Krittika',
          nakshatraId: 'n3_r1',
          rashiId: 'r1',
          symbol: '⚔'),
      NakshatraOption(
          id: '4',
          name: 'Krittika',
          nakshatraId: 'n3_r2',
          rashiId: 'r2',
          symbol: '⚔'),
      NakshatraOption(
          id: '5',
          name: 'Rohini',
          nakshatraId: 'n4',
          rashiId: 'r2',
          symbol: '🌸'),
    ]);
  }

  // Fixed filtering logic - now properly filters by single rashi_id
  List<NakshatraOption> getNakshatraOptionsForRashi(String? rashiId) {
    if (rashiId == null || rashiId.isEmpty) {
      return [];
    }

    return _nakshatraOptions
        .where((nakshatra) => nakshatra.rashiId == rashiId)
        .toList();
  }

  Future<void> _loadItems() async {
    _isLoading.value = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = await _prefsKey();
      final cached = prefs.getStringList(key);
      if (cached != null) {
        _items.assignAll(
            cached.map((e) => WatchlistItem.fromJson(jsonDecode(e))).toList());
      }
      if (!testing) {
        await _fetchFromDatabase();
        await _updateItemCounts();
      }
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

      if (result.documents.isNotEmpty) {
        _items.assignAll(result.documents.map((doc) {
          final data = doc.data;
          final watchlistKey =
              data['watchlistKey'] ?? data['watchlist_key'] ?? '';
          String? rashiId = data['rashiId'];
          String? nakshatraId = data['nakshatraId'];

          if (rashiId == null &&
              nakshatraId == null &&
              watchlistKey.isNotEmpty) {
            final parts = watchlistKey.split('-');
            if (parts.length == 2) {
              rashiId = parts[0];
              nakshatraId = parts[1];
            } else if (watchlistKey.startsWith('r')) {
              rashiId = watchlistKey;
            } else if (watchlistKey.startsWith('n')) {
              nakshatraId = watchlistKey;
            }
          }

          return WatchlistItem(
            id: doc.$id,
            name: data['name'] ?? '',
            count: data['count'] ?? 0,
            color: Color(data['colorValue'] ?? 0xFFEC407A),
            rashiId: rashiId,
            nakshatraId: nakshatraId,
            combinationKey: data['combinationKey'],
            chatRoomId: data['chatRoomId'],
            watchlistKey: watchlistKey,
            createdAt: ParsingUtils.parseDateTime(data['createdAt']),
            updatedAt: data['updatedAt'] != null
                ? ParsingUtils.parseDateTime(data['updatedAt'])
                : ParsingUtils.parseDateTime(data['createdAt']),
          );
        }).toList());
      } else {
        _items.clear();
      }
      await _saveItemsToPrefs();
      await _updateItemCounts();
    } catch (e, st) {
      logger.e('Error fetching watchlist from database',
          error: e, stackTrace: st);
    }
  }

  Future<void> _updateItemCounts() async {
    if (testing) return;
    final dbId = dotenv.env['APPWRITE_DATABASE_ID'] ?? 'StarChat_DB';
    for (int i = 0; i < _items.length; i++) {
      final item = _items[i];
      try {
        List<String> queries = [Query.equal('is_active', true)];
        if (item.combinationKey != null) {
          queries.add(Query.equal('combination_key', item.combinationKey!));
        } else if (item.chatRoomId != null) {
          final doc = await _auth.databases.getDocument(
            databaseId: dbId,
            collectionId: 'chat_rooms',
            documentId: item.chatRoomId!,
          );
          _items[i] = item.copyWith(
              count: doc.data['total_messages_today'] ??
                  doc.data['daily_messages'] ??
                  0);
          continue;
        } else {
          if (item.rashiId != null) {
            queries.add(Query.equal('rashi_id', item.rashiId!));
          }
          if (item.nakshatraId != null) {
            queries.add(Query.equal('nakshatra_id', item.nakshatraId!));
          }
        }
        final res = await _auth.databases.listDocuments(
          databaseId: dbId,
          collectionId: 'chat_rooms',
          queries: queries,
        );
        if (res.documents.isNotEmpty) {
          final count = res.documents.first.data['total_messages_today'] ??
              res.documents.first.data['daily_messages'] ??
              0;
          _items[i] = item.copyWith(count: count);
        }
      } catch (e, st) {
        logger.e('Error updating count for item ${item.name}',
            error: e, stackTrace: st);
      }
    }
    await _saveItemsToPrefs();
  }

  Future<void> refreshItemCounts() async {
    await _updateItemCounts();
    _showSuccessSnackbar('Refreshed', 'Message counts updated', Colors.blue);
  }

  /// Retrieve the chat room id associated with a [WatchlistItem]. If the item
  /// already contains a `chatRoomId`, that value is returned immediately.
  /// Otherwise the Appwrite database is queried using available identifiers such
  /// as `combinationKey`, `rashiId` and `nakshatraId`.
  Future<String?> fetchChatRoomId(WatchlistItem item) async {
    if (item.chatRoomId != null) return item.chatRoomId;

    final dbId = dotenv.env['APPWRITE_DATABASE_ID'] ?? 'StarChat_DB';
    try {
      final queries = <String>[Query.equal('is_active', true)];

      if (item.combinationKey != null) {
        queries.add(Query.equal('combination_key', item.combinationKey!));
      } else {
        if (item.rashiId != null) {
          queries.add(Query.equal('rashi_id', item.rashiId!));
        }
        if (item.nakshatraId != null) {
          queries.add(Query.equal('nakshatra_id', item.nakshatraId!));
        }
      }

      final res = await _auth.databases.listDocuments(
        databaseId: dbId,
        collectionId: 'chat_rooms',
        queries: queries,
      );

      if (res.documents.isNotEmpty) {
        return res.documents.first.$id;
      }
    } catch (e, st) {
      logger.e('Error finding chat room for item ${item.name}',
          error: e, stackTrace: st);
    }

    return null;
  }

  Map<String, dynamic> _itemDataForDb(WatchlistItem item, String uid,
      {int? order, DateTime? updatedAt}) {
    return {
      'userId': uid,
      'name': item.name,
      'count': item.count,
      'colorValue': item.color.value,
      'watchlistKey': item.watchlistKey,
      'createdAt': item.createdAt.toIso8601String(),
      'updatedAt': (updatedAt ?? DateTime.now()).toIso8601String(),
      'order': order ?? _items.indexOf(item),
      // Provide default values for optional schema fields
      'iconCodePoint': 0xe885,
      'iconFontFamily': 'MaterialIcons',
    };
  }

  Future<void> _saveItemsToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = await _prefsKey();
      final data = _items.map((e) => jsonEncode(e.toJson())).toList();
      await prefs.setStringList(key, data);
    } catch (e, st) {
      logger.e('Error saving watchlist locally', error: e, stackTrace: st);
    }
  }

  // Available colors for new items
  static const List<Color> availableColors = [
    Color(0xFFFFCDD2),
    Color(0xFFE1BEE7),
    Color(0xFFBBDEFB),
    Color(0xFFC8E6C9),
    Color(0xFFFFE0B2),
    Color(0xFFB2DFDB),
    Color(0xFFC5CAE9),
    Color(0xFFFFF9C4),
  ];

  // Fixed addThreeWatchlistItems method - now properly saves to database
  Future<void> addThreeWatchlistItems(
      RashiOption rashi, NakshatraOption nakshatra, Color color) async {
    try {
      final session = await _auth.account.get();
      final uid = session.$id;

      final items = [
        WatchlistItem(
          id: ID.unique(),
          name: rashi.name,
          count: 0,
          color: color,
          rashiId: rashi.rashiId,
          watchlistKey: rashi.rashiId,
        ),
        WatchlistItem(
          id: ID.unique(),
          name: nakshatra.name,
          count: 0,
          color: color,
          nakshatraId: nakshatra.nakshatraId,
          watchlistKey: nakshatra.nakshatraId,
        ),
        WatchlistItem(
          id: ID.unique(),
          name: '${rashi.name}-${nakshatra.name}',
          count: 0,
          color: color,
          rashiId: rashi.rashiId,
          nakshatraId: nakshatra.nakshatraId,
          watchlistKey: '${rashi.rashiId}-${nakshatra.nakshatraId}',
        ),
      ];

      // Add to local list first
      _items.addAll(items);
      await _saveItemsToPrefs();

      // Save to database (removed testing check)
      final dbId = dotenv.env['APPWRITE_DATABASE_ID'] ?? 'StarChat_DB';
      final collectionId =
          dotenv.env[_watchlistCollectionKey] ?? 'watchlist_items';

      for (int i = 0; i < items.length; i++) {
        final it = items[i];
        try {
          await _auth.databases.createDocument(
            databaseId: dbId,
            collectionId: collectionId,
            documentId: it.id,
            data: _itemDataForDb(it, uid,
                order: _items.length - items.length + i,
                updatedAt: DateTime.now()),
            permissions: [
              Permission.read(Role.user(uid)),
              Permission.update(Role.user(uid)),
              Permission.delete(Role.user(uid)),
            ],
          );
          logger.i('Successfully added item ${it.name} to database');
        } catch (e, st) {
          logger.e('Error adding item ${it.name} to database',
              error: e, stackTrace: st);
          // Don't remove from local list if database fails - user can try sync later
        }
      }

      _showSuccessSnackbar(
          'Added to Watchlist',
          'Added ${rashi.name}, ${nakshatra.name}, and their combination',
          Colors.green);
      HapticFeedback.lightImpact();
    } catch (e, st) {
      logger.e('Error adding items to watchlist', error: e, stackTrace: st);
      _showErrorSnackbar('Error', 'Failed to add items to watchlist');
    }
  }

  Future<void> addItem(WatchlistItem item) async {
    _items.add(item);
    await _saveItemsToPrefs();

    if (!testing) {
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
        _showErrorSnackbar('Error', 'Failed to add item');
      }
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

    if (!testing) {
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
        logger.e('Error removing item from watchlist',
            error: e, stackTrace: st);
        _showErrorSnackbar('Error', 'Failed to remove item');
      }
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
          bool success = true;
          if (!testing) {
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
              success = false;
              logger.e('Error restoring item to watchlist',
                  error: e, stackTrace: st);
            }
          }
          Get.back();
          if (success) {
            _showSuccessSnackbar(
                'Restored', '${item.name} has been restored', Colors.blue);
          } else {
            _showErrorSnackbar('Error', 'Failed to restore item');
          }
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

  Future<void> updateItem(String id, {Color? color}) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      _items[index] = _items[index].copyWith(
        color: color,
        updatedAt: DateTime.now(),
      );
      await _saveItemsToPrefs();
      if (!testing) {
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
          _showErrorSnackbar('Error', 'Failed to update item');
        }
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
    if (!testing) {
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
        _showErrorSnackbar('Error', 'Failed to reorder items');
      }
    }
    HapticFeedback.selectionClick();
  }

  Future<void> clearAllItems() async {
    final itemCount = _items.length;
    _items.clear();
    await _saveItemsToPrefs();
    if (!testing) {
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
        _showErrorSnackbar('Error', 'Failed to clear items');
      }
    }
    _showSuccessSnackbar(
        'Cleared', '$itemCount items removed from watchlist', Colors.orange);
  }

  void _showSuccessSnackbar(String title, String message, Color color) {
    if (Get.context == null) return;
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

  void _showErrorSnackbar(String title, String message) {
    if (Get.context == null) return;
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.shade100,
      colorText: Colors.red.shade800,
      icon: Icon(Icons.error_outline, color: Colors.red.shade800),
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
            opacity: value.clamp(0.0, 1.0),
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
        final clampedOpacity = value.clamp(0.0, 1.0);
        final scale = (0.8 + (0.2 * value)).clamp(0.0, double.infinity);
        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: clampedOpacity,
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
// SWIPEABLE CARD WIDGET - Fixed text color
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
    // Calculate adaptive text color based on the background
    final lightColor = _lightenColor(item.color, 0.4);
    final darkColor = item.color;
    final averageColor = Color.lerp(lightColor, darkColor, 0.5)!;
    final textColor = _getAdaptiveTextColor(averageColor);
    final secondaryTextColor = textColor.withOpacity(0.7);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [lightColor, darkColor],
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
                    color: secondaryTextColor,
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
                        style: TextStyle(
                          color: textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Key: ${item.watchlistKey}',
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Added ${_formatDate(item.createdAt)}',
                        style: TextStyle(
                          color: secondaryTextColor,
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
                    color: context.colorScheme.onPrimary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${item.count}',
                    style: TextStyle(
                      color: textColor,
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
              Icon(icon, color: context.colorScheme.onPrimary, size: 24),
              const SizedBox(height: 4),
              Text(
                text,
                style: TextStyle(
                  color: context.colorScheme.onPrimary,
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
                  backgroundColor: context.colorScheme.error,
                  foregroundColor: context.colorScheme.onError,
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
    final controller = Get.find<WatchlistController>();

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
                  onTap: () => _openChatRoom(context, item),
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
            opacity: value.clamp(0.0, 1.0),
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
    RashiOption? selectedRashi;
    NakshatraOption? selectedNakshatra;
    Color selectedColor = WatchlistController.availableColors.first;
    List<NakshatraOption> availableNakshatras = [];

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
                  const Text('Select Rashi:',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Obx(() => controller.isLoadingOptions
                      ? const CircularProgressIndicator()
                      : DropdownButtonFormField<RashiOption>(
                          value: selectedRashi,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Choose a Rashi',
                          ),
                          items: controller.rashiOptions
                              .map((r) => DropdownMenuItem(
                                  value: r,
                                  child: Text(
                                      '${r.symbol} ${r.name} (${r.rashiId})')))
                              .toList(),
                          onChanged: (r) {
                            setState(() {
                              selectedRashi = r;
                              selectedNakshatra = null;
                              // Fixed filtering logic
                              availableNakshatras = controller
                                  .getNakshatraOptionsForRashi(r?.rashiId);
                            });
                            HapticFeedback.selectionClick();
                          },
                        )),
                  const SizedBox(height: 16),
                  const Text('Select Nakshatra:',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<NakshatraOption>(
                    value: selectedNakshatra,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Choose a Nakshatra',
                    ),
                    items: availableNakshatras
                        .map((n) => DropdownMenuItem(
                            value: n,
                            child: Text(
                                '${n.symbol} ${n.name} (${n.nakshatraId})')))
                        .toList(),
                    onChanged: selectedRashi == null
                        ? null
                        : (n) {
                            setState(() => selectedNakshatra = n);
                            HapticFeedback.selectionClick();
                          },
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
                              ? Icon(Icons.check,
                                  color: _getAdaptiveTextColor(color), size: 20)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                  if (availableNakshatras.isEmpty && selectedRashi != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        'No nakshatras found for ${selectedRashi!.name}. Please try a different rashi.',
                        style: TextStyle(
                            color: Colors.orange.shade700, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Get.back(), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: (selectedRashi != null && selectedNakshatra != null)
                    ? () {
                        controller.addThreeWatchlistItems(
                            selectedRashi!, selectedNakshatra!, selectedColor);
                        Get.back();
                      }
                    : null,
                child: const Text('Add Items'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditItemDialog(BuildContext context, WatchlistController controller,
      WatchlistItem item) {
    Color selectedColor = item.color;

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
                              ? Icon(Icons.check,
                                  color: _getAdaptiveTextColor(color))
                              : null,
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
                  controller.updateItem(item.id, color: selectedColor);
                  Get.back();
                },
                child: const Text('Update'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openChatRoom(BuildContext context, WatchlistItem item) async {
    final controller = Get.find<WatchlistController>();
    final roomId = await controller.fetchChatRoomId(item);
    if (roomId != null) {
      Get.toNamed('/chat-room/$roomId');
    } else {
      Get.snackbar(
        'Chat Room',
        'Unable to locate chat room for ${item.name}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
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
              backgroundColor: context.colorScheme.error,
              foregroundColor: context.colorScheme.onError,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}
