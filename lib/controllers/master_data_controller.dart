import 'dart:convert';
import 'package:get/get.dart';
import 'package:appwrite/appwrite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../utils/logger.dart';
import '../controllers/auth_controller.dart';
import '../widgets/complete_enhanced_watchlist.dart';

class MasterDataController extends GetxController {
  final AuthController _auth = Get.find<AuthController>();

  final RxList<RashiOption> _rashiOptions = <RashiOption>[].obs;
  final RxList<NakshatraOption> _nakshatraOptions = <NakshatraOption>[].obs;
  final RxBool _isLoading = false.obs;

  List<RashiOption> get rashiOptions => _rashiOptions;
  List<NakshatraOption> get nakshatraOptions => _nakshatraOptions;
  bool get isLoading => _isLoading.value;

  static const String _rashiCacheKey = 'cached_rashi_options_v2';
  static const String _nakshatraCacheKey = 'cached_nakshatra_options_v2';

  @override
  void onInit() {
    super.onInit();
    _loadMasterData();
  }

  Future<void> _loadMasterData() async {
    _isLoading.value = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedRashi = prefs.getStringList(_rashiCacheKey);
      final cachedNakshatra = prefs.getStringList(_nakshatraCacheKey);
      if (cachedRashi != null && cachedNakshatra != null) {
        _rashiOptions.assignAll(
          cachedRashi.map((e) => RashiOption.fromJson(jsonDecode(e))).toList(),
        );
        _nakshatraOptions.assignAll(
          cachedNakshatra
              .map((e) => NakshatraOption.fromJson(jsonDecode(e)))
              .toList(),
        );
      }
      await _fetchMasterDataFromDatabase();
    } catch (e, st) {
      logger.e('Error loading master data', error: e, stackTrace: st);
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> _fetchMasterDataFromDatabase() async {
    final dbId = dotenv.env['APPWRITE_DATABASE_ID'] ?? 'StarChat_DB';
    try {
      final rashiResult = await _auth.databases.listDocuments(
        databaseId: dbId,
        collectionId: 'rasi_master',
        queries: [Query.orderAsc('name'), Query.limit(50)],
      );
      final rashiList =
          rashiResult.documents.map((e) => RashiOption.fromJson(e.data)).toList();
      if (rashiList.isNotEmpty) {
        _rashiOptions.assignAll(rashiList);
      }
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
      }
      await _cacheMasterData();
    } catch (e, st) {
      logger.e('Error fetching master data', error: e, stackTrace: st);
    }
  }

  Future<void> _cacheMasterData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rashiJson =
          _rashiOptions.map((e) => jsonEncode(e.toJson())).toList();
      final nakJson =
          _nakshatraOptions.map((e) => jsonEncode(e.toJson())).toList();
      await prefs.setStringList(_rashiCacheKey, rashiJson);
      await prefs.setStringList(_nakshatraCacheKey, nakJson);
    } catch (e) {
      logger.e('Error caching master data', error: e);
    }
  }

  List<NakshatraOption> getNakshatraForRashi(String? rashiId) {
    if (rashiId == null || rashiId.isEmpty) return [];
    return _nakshatraOptions
        .where((n) => n.rashiId == rashiId)
        .toList();
  }
}
