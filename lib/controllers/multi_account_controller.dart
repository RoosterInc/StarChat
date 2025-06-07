import 'dart:convert';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccountInfo {
  final String userId;
  final String username;
  final String profilePictureUrl;
  final String sessionId;

  AccountInfo({
    required this.userId,
    required this.username,
    required this.sessionId,
    this.profilePictureUrl = '',
  });

  factory AccountInfo.fromJson(Map<String, dynamic> json) {
    return AccountInfo(
      userId: json['userId'] as String,
      username: json['username'] as String? ?? '',
      sessionId: json['sessionId'] as String? ?? '',
      profilePictureUrl: json['profilePictureUrl'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'username': username,
        'sessionId': sessionId,
        'profilePictureUrl': profilePictureUrl,
      };
}

class MultiAccountController extends GetxController {
  static const _accountsKey = 'multi_accounts';
  static const _activeKey = 'active_account';

  final accounts = <AccountInfo>[].obs;
  final activeAccountId = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadAccounts();
  }

  Future<void> loadAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_accountsKey) ?? [];
    accounts.assignAll(
      data.map((e) => AccountInfo.fromJson(jsonDecode(e))).toList(),
    );
    activeAccountId.value = prefs.getString(_activeKey) ?? '';
  }

  Future<void> _saveAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _accountsKey,
      accounts.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  Future<void> _saveActiveAccount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeKey, activeAccountId.value);
  }

  AccountInfo? _findById(String id) {
    try {
      return accounts.firstWhere((e) => e.userId == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> addAccount(AccountInfo account) async {
    final existing = _findById(account.userId);
    if (existing == null) {
      if (accounts.length >= 3) {
        throw Exception('Maximum accounts reached');
      }
      accounts.add(account);
      await _saveAccounts();
    } else {
      accounts[accounts.indexOf(existing)] = account;
      await _saveAccounts();
    }
    activeAccountId.value = account.userId;
    await _saveActiveAccount();
  }

  Future<void> removeAccount(String userId) async {
    accounts.removeWhere((a) => a.userId == userId);
    await _saveAccounts();
    if (activeAccountId.value == userId) {
      activeAccountId.value = accounts.isNotEmpty ? accounts.first.userId : '';
      await _saveActiveAccount();
    }
  }

  Future<void> switchAccount(String userId) async {
    if (activeAccountId.value == userId) return;
    if (_findById(userId) != null) {
      activeAccountId.value = userId;
      await _saveActiveAccount();
    }
  }

  AccountInfo? get activeAccount => _findById(activeAccountId.value);
}
