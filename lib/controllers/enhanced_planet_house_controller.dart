import 'package:get/get.dart';
import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import 'dart:convert';
import '../models/planet_house_models.dart';
import 'auth_controller.dart';

class EnhancedPlanetHouseController extends GetxController {
  final AuthController _auth = Get.find<AuthController>();
  final logger = Logger();

  final RxList<PlanetHouseData> _planetHouseData = <PlanetHouseData>[].obs;
  final RxBool _isLoading = false.obs;
  final RxString _error = ''.obs;
  final RxString _currentAscendantSign = ''.obs;
  final RxString _lastFetchDate = ''.obs;

  List<PlanetHouseData> get planetHouseData => _planetHouseData;
  bool get isLoading => _isLoading.value;
  String get error => _error.value;
  String get currentAscendantSign => _currentAscendantSign.value;
  bool get hasData => _planetHouseData.isNotEmpty;
  String get lastFetchDate => _lastFetchDate.value;

  static const String _databaseIdKey = 'APPWRITE_DATABASE_ID';
  static const String _planetaryHousesCollectionKey =
      'PLANETARY_HOUSES_COLLECTION_ID';
  static const String _interpretationsCollectionKey =
      'PLANET_HOUSE_INTERPRETATIONS_COLLECTION_ID';

  static const String _cacheKeyPositions = 'planet_house_positions_v2';
  static const String _cacheKeyInterpretations =
      'planet_house_interpretations_v2';
  static const String _cacheKeyTimestamp = 'planet_house_cache_timestamp_v2';
  static const String _cacheKeyFetchDate = 'planet_house_fetch_date_v2';

  @override
  void onInit() {
    super.onInit();
    _loadPlanetHouseData();
  }

  Future<void> _loadPlanetHouseData() async {
    _isLoading.value = true;
    _error.value = '';

    try {
      final today = _getTodayDateKey();
      final lastFetch = await _getLastFetchDate();

      if (lastFetch == today && lastFetch.isNotEmpty) {
        final cachedData = await _loadFromCache();
        if (cachedData.isNotEmpty) {
          _planetHouseData.assignAll(cachedData);
          _lastFetchDate.value = lastFetch;
          _isLoading.value = false;
          return;
        }
      }

      await _fetchFromServer();
      await _setLastFetchDate(today);
      _lastFetchDate.value = today;
    } catch (e, stackTrace) {
      logger.e('Error loading planet house data',
          error: e, stackTrace: stackTrace);
      _error.value = 'Failed to load planet data. Please try again.';
      final cachedData = await _loadFromCache();
      if (cachedData.isNotEmpty) {
        _planetHouseData.assignAll(cachedData);
        _error.value = 'Using cached data. Unable to fetch latest updates.';
      } else {
        _showErrorSnackbar();
      }
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> _fetchFromServer() async {
    final dbId = dotenv.env[_databaseIdKey] ?? 'StarChat_DB';
    final positionsCollectionId =
        dotenv.env[_planetaryHousesCollectionKey] ?? 'planetary_houses';
    final interpretationsCollectionId =
        dotenv.env[_interpretationsCollectionKey] ??
            'planet_house_interpretations';

    final dateKey = _getTodayDateKey();
    logger.i('Fetching planet positions for date: $dateKey');

    var positionsResult = await _auth.databases.listDocuments(
      databaseId: dbId,
      collectionId: positionsCollectionId,
      queries: [
        Query.equal('date_key', dateKey),
        Query.orderAsc('planet'),
        Query.limit(25),
      ],
    );

    if (positionsResult.documents.isEmpty) {
      positionsResult = await _auth.databases.listDocuments(
        databaseId: dbId,
        collectionId: positionsCollectionId,
        queries: [
          Query.orderDesc('date_key'),
          Query.orderAsc('planet'),
          Query.limit(25),
        ],
      );
      if (positionsResult.documents.isEmpty) {
        throw Exception('No planet position data available in database');
      }
    }

    final positions = positionsResult.documents
        .map((doc) => PlanetHousePosition.fromJson(doc.data))
        .toList();

    final ascendantSigns = positions.map((p) => p.ascendantSign).toSet();
    if (ascendantSigns.isNotEmpty) {
      _currentAscendantSign.value = ascendantSigns.first;
    }

    final mainPlanets = [
      'Sun',
      'Moon',
      'Mars',
      'Mercury',
      'Jupiter',
      'Venus',
      'Saturn',
      'Rahu',
      'Ketu'
    ];
    final filteredPositions = positions
        .where((p) =>
            p.ascendantSign == _currentAscendantSign.value &&
            mainPlanets.contains(p.planet))
        .toList();

    List<PlanetHouseInterpretation> interpretations = [];
    if (_currentAscendantSign.value.isNotEmpty) {
      try {
        final interpretationsResult = await _auth.databases.listDocuments(
          databaseId: dbId,
          collectionId: interpretationsCollectionId,
          queries: [
            Query.equal('ascendant_sign', _currentAscendantSign.value),
            Query.orderAsc('planet'),
            Query.limit(50),
          ],
        );

        interpretations = interpretationsResult.documents
            .map((doc) => PlanetHouseInterpretation.fromJson(doc.data))
            .toList();
      } catch (e) {
        logger.w('Failed to fetch interpretations: $e');
      }
    }

    final combinedData =
        _combinePositionsAndInterpretations(filteredPositions, interpretations);
    final orderedData = _ensureAllPlanets(combinedData, mainPlanets);

    _planetHouseData.assignAll(orderedData);
    await _saveToCache(orderedData);
  }

  List<PlanetHouseData> _ensureAllPlanets(
      List<PlanetHouseData> data, List<String> mainPlanets) {
    final Map<String, PlanetHouseData> dataMap = {
      for (var item in data) item.position.planet: item
    };
    return mainPlanets.map((planet) {
      if (dataMap.containsKey(planet)) {
        return dataMap[planet]!;
      } else {
        final mockPosition = PlanetHousePosition(
          date: _getTodayDateKey(),
          dateKey: _getTodayDateKey(),
          year: DateTime.now().year,
          month: DateTime.now().month,
          day: DateTime.now().day,
          ascendantSign: _currentAscendantSign.value.isNotEmpty
              ? _currentAscendantSign.value
              : 'Aries',
          ascendantSymbol: '♈',
          ascendantIndex: 1,
          planet: planet,
          planetSign: 'Unknown',
          planetSignSymbol: '?',
          planetDegrees: 0.0,
          planetLongitude: 0.0,
          houseNumber: (mainPlanets.indexOf(planet) % 12) + 1,
          houseName: _getHouseName((mainPlanets.indexOf(planet) % 12) + 1),
          houseArea: 'Unknown',
          houseMeaning: 'Data not available',
          description: 'Position data not available for this planet',
          generatedAt: DateTime.now(),
        );
        return PlanetHouseData(position: mockPosition, interpretation: null);
      }
    }).toList();
  }

  String _getHouseName(int houseNumber) {
    const houseNames = [
      'First House',
      'Second House',
      'Third House',
      'Fourth House',
      'Fifth House',
      'Sixth House',
      'Seventh House',
      'Eighth House',
      'Ninth House',
      'Tenth House',
      'Eleventh House',
      'Twelfth House'
    ];
    return houseNames[(houseNumber - 1) % 12];
  }

  List<PlanetHouseData> _combinePositionsAndInterpretations(
    List<PlanetHousePosition> positions,
    List<PlanetHouseInterpretation> interpretations,
  ) {
    final Map<String, PlanetHouseInterpretation> interpretationMap = {};
    for (var interp in interpretations) {
      final key = '${interp.planet}_${interp.houseNumber}';
      interpretationMap[key] = interp;
    }

    return positions.map((position) {
      final key = '${position.planet}_${position.houseNumber}';
      final interpretation = interpretationMap[key];
      return PlanetHouseData(
        position: position,
        interpretation: interpretation,
      );
    }).toList();
  }

  String _getTodayDateKey() {
    final now = DateTime.now();
    return '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
  }

  Future<String> _getLastFetchDate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_cacheKeyFetchDate) ?? '';
    } catch (e) {
      logger.e('Error getting last fetch date', error: e);
      return '';
    }
  }

  Future<void> _setLastFetchDate(String dateKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKeyFetchDate, dateKey);
    } catch (e) {
      logger.e('Error setting last fetch date', error: e);
    }
  }

  Future<List<PlanetHouseData>> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final positionsJson = prefs.getStringList(_cacheKeyPositions);
      final interpretationsJson = prefs.getStringList(_cacheKeyInterpretations);
      final ascendantSign = prefs.getString('cached_ascendant_sign');
      if (positionsJson == null) {
        return [];
      }
      if (ascendantSign != null) {
        _currentAscendantSign.value = ascendantSign;
      }
      final positions = positionsJson
          .map((json) => PlanetHousePosition.fromJson(jsonDecode(json)))
          .toList();
      final interpretations = interpretationsJson
              ?.map((json) =>
                  PlanetHouseInterpretation.fromJson(jsonDecode(json)))
              .toList() ??
          [];
      return _combinePositionsAndInterpretations(positions, interpretations);
    } catch (e, stackTrace) {
      logger.e('Error loading from cache', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  Future<void> _saveToCache(List<PlanetHouseData> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final positionsJson =
          data.map((item) => jsonEncode(item.position.toJson())).toList();
      final interpretationsJson = data
          .where((item) => item.interpretation != null)
          .map((item) => jsonEncode(item.interpretation!.toJson()))
          .toList();
      await prefs.setStringList(_cacheKeyPositions, positionsJson);
      await prefs.setStringList(_cacheKeyInterpretations, interpretationsJson);
      await prefs.setString(
          _cacheKeyTimestamp, DateTime.now().toIso8601String());
      if (_currentAscendantSign.value.isNotEmpty) {
        await prefs.setString(
            'cached_ascendant_sign', _currentAscendantSign.value);
      }
    } catch (e, stackTrace) {
      logger.e('Error saving to cache', error: e, stackTrace: stackTrace);
    }
  }

  Future<void> forceRefreshData() async {
    _lastFetchDate.value = '';
    await _setLastFetchDate('');
    await _loadPlanetHouseData();
    Get.snackbar('Refreshed', 'Planet data updated successfully',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2));
  }

  PlanetHouseData? getPlanetData(String planetName) {
    return _planetHouseData.firstWhereOrNull(
      (data) => data.position.planet.toLowerCase() == planetName.toLowerCase(),
    );
  }

  List<PlanetHouseData> get planetsSortedByHouse {
    final list = List<PlanetHouseData>.from(_planetHouseData);
    list.sort(
        (a, b) => a.position.houseNumber.compareTo(b.position.houseNumber));
    return list;
  }

  List<PlanetHouseData> get planetsSortedByStrength {
    final list = List<PlanetHouseData>.from(_planetHouseData);
    list.sort((a, b) => (b.interpretation?.strengthRating ?? 0)
        .compareTo(a.interpretation?.strengthRating ?? 0));
    return list;
  }

  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKeyPositions);
      await prefs.remove(_cacheKeyInterpretations);
      await prefs.remove(_cacheKeyTimestamp);
      await prefs.remove(_cacheKeyFetchDate);
      await prefs.remove('cached_ascendant_sign');
    } catch (e) {
      logger.e('Error clearing cache', error: e);
    }
  }

  void _showErrorSnackbar() {
    Get.snackbar(
      'Error',
      'Failed to load planet data. Please check your connection and try again.',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 6),
      mainButton: TextButton(
        onPressed: forceRefreshData,
        child: const Text('Retry'),
      ),
    );
  }

  @override
  void onClose() {
    _planetHouseData.close();
    _isLoading.close();
    _error.close();
    _currentAscendantSign.close();
    _lastFetchDate.close();
    super.onClose();
  }
}
