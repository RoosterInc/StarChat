import 'dart:convert';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccountInfo {
  final String appwriteUserId; // Renamed from userId
  final String username;
  final String profilePictureUrl;
  final String email;
  final String tokenGenerationUserId;
  final String tokenSecret;
  final String? currentSessionId; // Optional

  AccountInfo({
    required this.appwriteUserId,
    required this.username,
    required this.email,
    required this.tokenGenerationUserId,
    required this.tokenSecret,
    this.currentSessionId,
    this.profilePictureUrl = '',
  });

  factory AccountInfo.fromJson(Map<String, dynamic> json) {
    return AccountInfo(
      appwriteUserId: json['appwriteUserId'] as String, // Changed from 'userId'
      username: json['username'] as String? ?? '',
      email: json['email'] as String,
      tokenGenerationUserId: json['tokenGenerationUserId'] as String,
      tokenSecret: json['tokenSecret'] as String,
      currentSessionId: json['currentSessionId'] as String?,
      profilePictureUrl: json['profilePictureUrl'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'appwriteUserId': appwriteUserId, // Changed from 'userId'
        'username': username,
        'email': email,
        'tokenGenerationUserId': tokenGenerationUserId,
        'tokenSecret': tokenSecret,
        'currentSessionId': currentSessionId,
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
      return accounts.firstWhere((e) => e.appwriteUserId == id); // Changed to appwriteUserId
    } catch (_) {
      return null;
    }
  }

  Future<void> addAccount(AccountInfo account) async {
    final existing = _findById(account.appwriteUserId); // Changed to appwriteUserId
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
    activeAccountId.value = account.appwriteUserId; // Changed to appwriteUserId
    await _saveActiveAccount();
  }

  Future<void> removeAccount(String appwriteUserId) async { // Changed parameter name
    accounts.removeWhere((a) => a.appwriteUserId == appwriteUserId); // Changed to appwriteUserId
    await _saveAccounts();
    if (activeAccountId.value == appwriteUserId) { // Changed to appwriteUserId
      activeAccountId.value = accounts.isNotEmpty ? accounts.first.appwriteUserId : ''; // Changed to appwriteUserId
      await _saveActiveAccount();
    }
  }

  Future<void> switchAccount(String appwriteUserId) async { // Changed parameter name
    if (activeAccountId.value == appwriteUserId) return; // Changed to appwriteUserId
    if (_findById(appwriteUserId) != null) { // Changed to appwriteUserId
      activeAccountId.value = appwriteUserId; // Changed to appwriteUserId
      await _saveActiveAccount();
    }
  }

  AccountInfo? get activeAccount => _findById(activeAccountId.value);
}
