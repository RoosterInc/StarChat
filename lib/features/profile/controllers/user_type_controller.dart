import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

import '../../../shared/utils/logger.dart';


/// Manages the current user's type and related helpers.
///
/// This controller acts as the single source of truth for whether
/// the current user is a "General User" or an "Astrologer".  It
/// exposes reactive values for easy UI binding and persists the
/// chosen user type to [SharedPreferences].
class UserTypeController extends GetxController {
  // private reactive fields
  final RxString _userType = _defaultUserType.obs;
  final RxBool _isAstrologer = false.obs;
  final RxBool _isLoading = false.obs;
  final RxBool _isInitialized = false.obs;

  // public getters
  String get userType => _userType.value;
  bool get isAstrologer => _isAstrologer.value;
  bool get isLoading => _isLoading.value;
  bool get isInitialized => _isInitialized.value;

  // reactive values for the UI
  RxString get userTypeRx => _userType;
  RxBool get isAstrologerRx => _isAstrologer;
  RxBool get isLoadingRx => _isLoading;

  static const String _userTypeKey = 'user_type_v2';
  static const String _defaultUserType = 'General User';
  static const List<String> _validUserTypes = ['General User', 'Astrologer'];

  /// Expose the storage key for other classes (e.g. [AuthController])
  static String get storageKey => _userTypeKey;

  final _logger = logger;

  @override
  void onInit() {
    super.onInit();
    _logger.i('[UserType] initializing');
    _initializeUserType();
  }

  /// Loads the saved user type from storage. If none exists a default
  /// value is written.
  Future<void> _initializeUserType() async {
    if (_isInitialized.value) return;
    _isLoading.value = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_userTypeKey);
      if (saved != null && _validUserTypes.contains(saved)) {
        await _setUserTypeInternal(saved, saveToStorage: false);
      } else {
        await _setUserTypeInternal(_defaultUserType, saveToStorage: true);
      }
      _isInitialized.value = true;
      _logger.i('[UserType] init complete: $_userType');
    } catch (e, st) {
      _logger.e('[UserType] initialization failed', error: e, stackTrace: st);
      await _setUserTypeInternal(_defaultUserType, saveToStorage: false);
      _isInitialized.value = true;
      _showErrorSnackbar('User Type Error', 'Failed to load preference');
    } finally {
      _isLoading.value = false;
    }
  }

  /// Updates user type and persists if requested.
  Future<void> _setUserTypeInternal(String type,
      {bool saveToStorage = true}) async {
    if (!_validUserTypes.contains(type)) {
      _logger.w('[UserType] invalid type: $type');
      return;
    }

    _userType.value = type;
    _isAstrologer.value = type == 'Astrologer';

    if (saveToStorage) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userTypeKey, type);
      } catch (e, st) {
        _logger.e('[UserType] failed saving', error: e, stackTrace: st);
      }
    }
  }

  /// Public API to change the user type.
  Future<void> updateUserType(String type) async {
    if (!_validUserTypes.contains(type)) {
      _showErrorSnackbar('Invalid User Type', 'Please select a valid type');
      return;
    }
    if (_userType.value == type) return;
    _isLoading.value = true;
    try {
      await _setUserTypeInternal(type, saveToStorage: true);
      _showSuccessSnackbar('User Type Updated', 'You are now $type');
    } catch (e, st) {
      _logger.e('[UserType] update failed', error: e, stackTrace: st);
      _showErrorSnackbar('Update Failed', 'Could not update user type');
    } finally {
      _isLoading.value = false;
    }
  }

  /// Sets the user type without any UI notifications. Intended for
  /// synchronization with server values (e.g. during login).
  Future<void> applyUserType(String type) async {
    if (!_validUserTypes.contains(type)) {
      type = _defaultUserType;
    }
    await _setUserTypeInternal(type, saveToStorage: true);
  }

  /// Convenience method to toggle between the two known types.
  Future<void> toggleUserType() async {
    final next = _isAstrologer.value ? 'General User' : 'Astrologer';
    await updateUserType(next);
  }

  /// Reloads the type from storage.
  Future<void> reloadUserType() async {
    _logger.i('[UserType] force reload');
    _isInitialized.value = false;
    await _initializeUserType();
  }

  /// Clears stored preference and resets to default.
  Future<void> clearUserTypeData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userTypeKey);
      await _setUserTypeInternal(_defaultUserType, saveToStorage: false);
      _showSuccessSnackbar('Reset Complete', 'User type reset');
    } catch (e, st) {
      _logger.e('[UserType] clear failed', error: e, stackTrace: st);
      _showErrorSnackbar('Reset Failed', 'Could not clear user type');
    }
  }

  /// Returns tab configuration depending on current user type.
  List<String> getTabsForCurrentUser() {
    if (_isAstrologer.value) {
      return [
        'Home',
        'Requests',
        'Questions',
        'Events',
        'Messages',
        'Predictions'
      ];
    }
    return ['Home', 'Feed', 'Events', 'Predictions', 'Messages'];
  }

  /// Checks availability of a given [UserFeature].
  bool hasFeature(UserFeature feature) {
    switch (feature) {
      case UserFeature.createPredictions:
      case UserFeature.manageRequests:
      case UserFeature.accessPredictionTools:
        return _isAstrologer.value;
      case UserFeature.viewPredictions:
      case UserFeature.sendMessages:
      case UserFeature.viewEvents:
        return true;
    }
  }

  /// Debug helper
  Map<String, dynamic> getDebugInfo() => {
        'userType': _userType.value,
        'isAstrologer': _isAstrologer.value,
        'isLoading': _isLoading.value,
        'isInitialized': _isInitialized.value,
        'timestamp': DateTime.now().toIso8601String(),
      };

  void _showSuccessSnackbar(String title, String message) {
    if (Get.context == null) return;
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.shade100,
      colorText: Colors.green.shade800,
      icon: Icon(Icons.check_circle, color: Colors.green.shade800),
      duration: const Duration(seconds: 3),
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
      icon: Icon(Icons.error, color: Colors.red.shade800),
      duration: const Duration(seconds: 4),
    );
  }

  @override
  void onClose() {
    _logger.i('[UserType] controller closing');
    super.onClose();
  }
}

/// Features that may only be available to certain user types.
enum UserFeature {
  createPredictions,
  manageRequests,
  accessPredictionTools,
  viewPredictions,
  sendMessages,
  viewEvents,
}

/// Utility helpers related to the user type.
class UserTypeUtils {
  static const Map<String, IconData> userTypeIcons = {
    'General User': Icons.person,
    'Astrologer': Icons.auto_awesome,
  };

  static const Map<String, Color> userTypeColors = {
    'General User': Colors.blue,
    'Astrologer': Colors.purple,
  };

  static IconData getIconForUserType(String type) {
    return userTypeIcons[type] ?? Icons.person;
  }

  static Color getColorForUserType(String type) {
    return userTypeColors[type] ?? Colors.grey;
  }
}
