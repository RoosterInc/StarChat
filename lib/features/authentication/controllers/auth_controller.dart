import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:appwrite/appwrite.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:email_validator/email_validator.dart'; // Added for email validation
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/utils/logger.dart';
import '../../profile/controllers/user_type_controller.dart';

class AuthController extends GetxController {
  final Client client = Client();
  late Account account;
  late Databases databases;
  late Storage storage;

  final isLoading = false.obs;
  final isOTPSent = false.obs;
  final justLoggedOut = false.obs;
  final _sessionCheckLock = false.obs;
  final isCheckingUsername = false.obs;
  final usernameAvailable = false.obs;
  final hasCheckedUsername = false.obs;
  final username = ''.obs;
  final displayName = ''.obs;
  final profilePictureUrl = ''.obs;
  final isUsernameValid = false.obs;
  final usernameText = ''.obs;
  final emailError = ''.obs;
  final otpError = ''.obs;
  final usernameError = ''.obs;
  Timer? _usernameDebounce;
  static const Duration usernameDebounceDuration = Duration(milliseconds: 500);
  String? _currentCheckingUsername;
  late TextEditingController usernameController;

  late TextEditingController emailController;
  late TextEditingController otpController;

  final birthRashiId = ''.obs;
  final birthNakshatraId = ''.obs;

  String? userId;

  // Timers and related variables
  final canResendOTP = true.obs;
  final resendCooldown = 60.obs;
  Timer? _resendTimer;

  final otpExpiration = 300.obs;
  Timer? _otpTimer;

  // Constants for durations
  static const int resendCooldownDuration = 60; // in seconds
  static const int otpExpirationDuration = 300; // in seconds

  // Environment variable keys
  static const String _endpointKey = 'APPWRITE_ENDPOINT';
  static const String _projectIdKey = 'APPWRITE_PROJECT_ID';
  static const String _databaseIdKey = 'APPWRITE_DATABASE_ID';
  static const String _profilesCollectionKey = 'USER_PROFILES_COLLECTION_ID';
  static const String _usernamesHistoryCollectionKey =
      'USER_NAMES_HISTORY_COLLECTION_ID';
  static const String _bucketIdKey = 'PROFILE_PICTURES_BUCKET_ID';

  @override
  void onInit() {
    super.onInit();
    final endpoint = dotenv.env[_endpointKey] ?? '';
    final projectId = dotenv.env[_projectIdKey] ?? '';
    client.setEndpoint(endpoint).setProject(projectId);

    emailController = TextEditingController();
    otpController = TextEditingController();
    usernameController = TextEditingController();
    usernameController.addListener(() {
      usernameText.value = usernameController.text;
    });

    account = Account(client);
    databases = Databases(client);
    storage = Storage(client);
  }

  @override
  void onClose() {
    emailController.dispose();
    otpController.dispose();
    usernameController.dispose();
    usernameText.value = '';
    emailError.value = '';
    otpError.value = '';
    usernameError.value = '';
    displayName.value = '';
    birthRashiId.value = '';
    birthNakshatraId.value = '';
    cancelTimers();
    super.onClose();
  }

  Future<void> checkExistingSession({bool navigateOnMissing = true}) async {
    // If a session check is already in progress, wait for it to finish
    if (_sessionCheckLock.value) {
      logger.i(
          "[Auth] checkExistingSession: Already checking session, waiting...");

      int attempts = 0;
      while (_sessionCheckLock.value && attempts < 50) {
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
      }

      if (_sessionCheckLock.value) {
        logger.w(
            "[Auth] checkExistingSession: Timeout waiting for session check, forcing unlock");
        _sessionCheckLock.value = false;
      } else {
        logger
            .i("[Auth] checkExistingSession: Previous session check completed");
        return; // Navigation already handled
      }
    }

    _sessionCheckLock.value = true;

    try {
      if (justLoggedOut.value) {
        justLoggedOut.value = false;
        logger.i(
            "[Auth] checkExistingSession: 'justLoggedOut' flag was true. Navigating to logout splash.");
        Get.offAllNamed('/logged-out');
        return;
      }

      logger.i(
          "[Auth] checkExistingSession: Attempting to get existing session.");

      isLoading.value = true;
      final session = await account.get();
      logger.i(
          "[Auth] checkExistingSession: account.get() succeeded. User ID: ${session.$id}, Email: ${session.email}");

      userId = session.$id;
      bool hasUsername = await ensureUsername();
      if (hasUsername) {
        logger.i(
            "[Auth] checkExistingSession: User has username. Current route: ${Get.currentRoute}");
        if (Get.currentRoute != '/home') {
          logger.i("[Auth] checkExistingSession: Navigating to /home from ${Get.currentRoute}");
          Get.offAllNamed('/home');
        } else {
          logger.i(
              "[Auth] checkExistingSession: Already on /home, not navigating from checkExistingSession.");
        }
      } else {
        logger.i(
            "[Auth] checkExistingSession: User does NOT have username. Current route: ${Get.currentRoute}");
        if (Get.currentRoute != '/set_username') {
          logger.i("[Auth] checkExistingSession: Navigating to /set_username");
          Get.offAllNamed('/set_username');
        } else {
          logger.i(
              "[Auth] checkExistingSession: Already on /set_username, not navigating.");
        }
      }
    } on AppwriteException catch (e) {
      logger.e(
          "[Auth] checkExistingSession: account.get() failed with AppwriteException. Code: ${e.code}, Message: ${e.message}");
      if (e.code == 401 && navigateOnMissing) {
        Get.offAllNamed('/');
      }
    } catch (e) {
      logger.e("[Auth] checkExistingSession: Caught general error: $e");
    } finally {
      isLoading.value = false;
      _sessionCheckLock.value = false;
      logger.i("[Auth] checkExistingSession: Finished.");
    }
  }

  bool isValidEmail(String email) {
    return EmailValidator.validate(email);
  }

  bool isValidOTP(String otp) {
    final otpRegex = RegExp(r'^\d{6}$');
    return otpRegex.hasMatch(otp);
  }

  bool isValidUsername(String name) {
    final usernameRegex = RegExp(r'^[a-zA-Z0-9_]{3,15}$');
    return usernameRegex.hasMatch(name);
  }

  Future<void> sendOTP() async {
    FocusManager.instance.primaryFocus?.unfocus();
    String email = emailController.text.trim();

    if (!isValidEmail(email)) {
      emailError.value = 'invalid_email_message'.tr;
      Get.snackbar(
        'invalid_email'.tr,
        emailError.value,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    } else {
      emailError.value = '';
    }

    if (!canResendOTP.value) {
      Get.snackbar(
        'wait'.tr,
        'resend_otp_in'.trParams({'seconds': resendCooldown.value.toString()}),
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // Check network connectivity
    final connectivityResults = await Connectivity().checkConnectivity();
    if (connectivityResults.contains(ConnectivityResult.none)) {
      Get.snackbar(
        'no_internet'.tr,
        'check_internet'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isLoading.value = true;
    try {
      final result = await account.createEmailToken(
        userId: ID.unique(),
        email: email,
      );

      userId = result.userId;
      isOTPSent.value = true;

      Get.snackbar(
        'success'.tr,
        'otp_sent'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );

      // Start cooldown timer after sending OTP
      canResendOTP.value = false;
      startResendCooldownTimer();

      // Start OTP expiration timer
      startOTPExpirationTimer();
    } on AppwriteException catch (e) {
      logger.e('AppwriteException in sendOTP', error: e);
      String errorMessage = 'failed_to_send_otp'.tr;

      if (e.code == 400) {
        errorMessage = 'invalid_email_message'.tr;
      } else if (e.code == 429) {
        errorMessage = 'too_many_requests'.tr;
      } else if (e.code == 500) {
        errorMessage = 'server_error'.tr;
      }

      Get.snackbar(
        'error'.tr,
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      logger.e('Unknown error in sendOTP', error: e);
      Get.snackbar(
        'error'.tr,
        'unexpected_error'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> verifyOTP() async {
    // Close any open snackbars to avoid context issues when navigating
    Get.closeAllSnackbars();
    // Ensure any open keyboard is dismissed to prevent rendering errors
    FocusManager.instance.primaryFocus?.unfocus();
    String otp = otpController.text.trim();

    if (!isValidOTP(otp)) {
      otpError.value = 'invalid_otp_message'.tr;
      Get.snackbar(
        'invalid_otp'.tr,
        otpError.value,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    } else if (otpExpiration.value <= 0) {
      otpError.value = 'otp_expired_message'.tr;
      Get.snackbar(
        'otp_expired'.tr,
        otpError.value,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    } else {
      otpError.value = '';
    }

    // Check network connectivity
    final connectivityResults = await Connectivity().checkConnectivity();
    if (connectivityResults.contains(ConnectivityResult.none)) {
      Get.snackbar(
        'no_internet'.tr,
        'check_internet'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isLoading.value = true;
    try {
      final session = await account.get();
      userId = session.$id;
      Get.offAllNamed('/home');
      clearControllers();
      isOTPSent.value = false;
      await Future.delayed(const Duration(milliseconds: 100));
      await ensureUsername();
    } on AppwriteException {
      logger.i('No existing session, verifying OTP...');
      if (userId == null) {
        logger.e('verifyOTP called with null userId');
        Get.snackbar(
          'error'.tr,
          'unauthorized'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
        isLoading.value = false;
        return;
      }
      try {
        final session = await account.createSession(
          userId: userId!,
          secret: otp,
        );

        userId = session.$id;
        otpError.value = '';
        bool hasUsername = await ensureUsername();
        if (hasUsername) {
          Get.offAllNamed('/home');
        } else {
          Get.offAllNamed('/set_username');
        }
        clearControllers();
        isOTPSent.value = false;
      } on AppwriteException catch (e) {
        logger.e('AppwriteException in verifyOTP', error: e);
        String errorMessage = 'failed_to_verify_otp'.tr;

        if (e.code == 400 || e.code == 404) {
          if (otpExpiration.value <= 0) {
            errorMessage = 'otp_expired_message'.tr;
          } else {
            errorMessage = 'incorrect_otp_message'.tr;
          }
        } else if (e.code == 401) {
          if (otpExpiration.value <= 0) {
            errorMessage = 'otp_expired_message'.tr;
          } else {
            errorMessage = 'incorrect_otp_message'.tr;
          }
        } else if (e.code == 429) {
          errorMessage = 'too_many_requests'.tr;
        } else if (e.code == 500) {
          errorMessage = 'server_error'.tr;
        }

        otpError.value = errorMessage;
        Get.snackbar(
          'error'.tr,
          errorMessage,
          snackPosition: SnackPosition.BOTTOM,
        );
      } catch (e) {
        logger.e('Unknown error in verifyOTP', error: e);
        Get.snackbar(
          'error'.tr,
          'unexpected_error'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      logger.e('Error in verifyOTP', error: e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resendOTP() async {
    await sendOTP();
  }

  void startResendCooldownTimer() {
    _resendTimer?.cancel();
    resendCooldown.value = resendCooldownDuration;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      resendCooldown.value--;
      if (resendCooldown.value <= 0) {
        timer.cancel();
        canResendOTP.value = true;
      }
    });
  }

  void startOTPExpirationTimer() {
    _otpTimer?.cancel();
    otpExpiration.value = otpExpirationDuration;
    _otpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      otpExpiration.value--;
      if (otpExpiration.value <= 0) {
        timer.cancel();
        isOTPSent.value = false;
        Get.snackbar(
          'otp_expired'.tr,
          'otp_expired_message'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    });
  }

  void goBackToEmailInput() {
    cancelTimers();
    otpController.clear();
    isOTPSent.value = false;
    canResendOTP.value = true;
  }

  void cancelTimers() {
    _resendTimer?.cancel();
    _otpTimer?.cancel();
    _usernameDebounce?.cancel();
  }

  void clearControllers() {
    emailController.clear();
    otpController.clear();
    usernameController.clear();
    usernameText.value = '';
    cancelTimers();
  }

  /// Reset all sign in related state back to defaults. Useful when navigating
  /// to the sign in page from the account switcher so leftover values don't
  /// disable the form.
  void resetSignInState() {
    clearControllers();
    isLoading.value = false;
    isOTPSent.value = false;
    emailError.value = '';
    otpError.value = '';
    usernameError.value = '';
    canResendOTP.value = true;
    resendCooldown.value = resendCooldownDuration;
    otpExpiration.value = otpExpirationDuration;
  }

  Future<bool> ensureUsername() async {
    logger.i(
        '[Auth] ensureUsername: Called. Current local userId: $userId, Current local username: ${username.value}');

    final prefs = await SharedPreferences.getInstance();
    final dbId = dotenv.env[_databaseIdKey] ?? 'StarChat_DB';
    final collectionId = dotenv.env[_profilesCollectionKey] ?? 'user_profiles';

    try {
      final session = await account.get();
      final uid = session.$id;
      userId = uid;
      logger.i(
          "[Auth] ensureUsername: Fetched session successfully. User ID for query: $uid, Email: ${session.email}");

      final result = await databases.listDocuments(
        databaseId: dbId,
        collectionId: collectionId,
        queries: [
          Query.equal('userId', uid),
          Query.limit(1),
        ],
      );
      logger.i(
          "[Auth] ensureUsername: Database query for userId '$uid' found ${result.documents.length} documents.");

      if (result.documents.isNotEmpty) {
        final data = result.documents.first.data;
        final fetchedUsername = data['username'];
        final fetchedDisplayName = data['displayname'];
        final fetchedTypeRaw = data['userType'];
        birthRashiId.value = data['birth_rashi'] ?? '';
        birthNakshatraId.value = data['birth_nakshatra'] ?? '';
        logger.i(
            "[Auth] ensureUsername: Document found. Username from DB: '$fetchedUsername'. Profile Pic URL: '${data['profilePicture']}'");
        if (fetchedUsername != null && fetchedUsername != '') {
          username.value = fetchedUsername;
          displayName.value = fetchedDisplayName ?? '';
          if (data['profilePicture'] != null && data['profilePicture'] != '') {
            profilePictureUrl.value = data['profilePicture'];
          }
          if (fetchedTypeRaw != null) {
            final mappedType = fetchedTypeRaw == 'Regular User'
                ? 'General User'
                : fetchedTypeRaw;
            try {
              final userTypeController = Get.find<UserTypeController>();
              await userTypeController.applyUserType(mappedType);
            } catch (_) {}
          }
          await prefs.setString('username', username.value);
          await prefs.setString('displayname', displayName.value);
          logger.i(
              "[Auth] ensureUsername: Returning true (username found and set).");
          return true;
        } else {
          logger.i(
              "[Auth] ensureUsername: Document found but username is null or empty in DB.");
        }
      } else {
        logger.i(
            "[Auth] ensureUsername: No document found in DB for userId '$uid'.");
      }

      await prefs.remove('username');
      await prefs.remove('displayname');
      username.value = '';
      displayName.value = '';
      profilePictureUrl.value = '';
      birthRashiId.value = '';
      birthNakshatraId.value = '';
      logger.i(
          "[Auth] ensureUsername: Returning false (no username found on server for this session/UID, or it was empty).");
      return false;
    } catch (e) {
      if (e is AppwriteException) {
        logger.e(
            "[Auth] ensureUsername: AppwriteException. Code: ${e.code}, Message: ${e.message}");
      } else {
        logger.e("[Auth] ensureUsername: General error: $e");
      }

      final cachedName = prefs.getString('username');
      final cachedDisplay = prefs.getString('displayname');
      logger.i(
          "[Auth] ensureUsername: Attempting fallback to cached username. Cached name: '$cachedName'");
      if (cachedName != null) {
        username.value = cachedName;
        displayName.value = cachedDisplay ?? '';
        logger.i(
            "[Auth] ensureUsername: Returning true (using cached username due to server error).");
        return true;
      }

      logger.i(
          "[Auth] ensureUsername: Returning false (error and no cached username).");
      return false;
    }
  }


  Future<bool> _checkUsernameAvailability(String name) async {
    // Validate input consistency
    if (name != _currentCheckingUsername || name != usernameText.value) {
      logger.i(
          "[Auth] _checkUsernameAvailability: Name mismatch, aborting check. Input: '$name', Current: '$_currentCheckingUsername', Text: '${usernameText.value}'");
      return false;
    }

    if (name.isEmpty) {
      usernameAvailable.value = false;
      isCheckingUsername.value = false;
      logger
          .i("[Auth] _checkUsernameAvailability: Empty name, returning false");
      return false;
    }

    isCheckingUsername.value = true;
    logger.i(
        "[Auth] _checkUsernameAvailability: Starting availability check for username: '$name'");

    final dbId = dotenv.env[_databaseIdKey] ?? 'StarChat_DB';
    final historyCollectionId =
        dotenv.env[_usernamesHistoryCollectionKey] ?? 'user_names_history';

    logger.i(
        "[Auth] _checkUsernameAvailability: Using dbId: '$dbId', historyCollectionId: '$historyCollectionId'");

    try {
      // Double-check input consistency before query
      if (name != _currentCheckingUsername || name != usernameText.value) {
        logger.i(
            "[Auth] _checkUsernameAvailability: Name changed during check, aborting");
        return false;
      }

      // Check against user_names_history collection for availability
      logger.i(
          "[Auth] _checkUsernameAvailability: Querying user_names_history for username: '$name'");

      final result = await databases.listDocuments(
        databaseId: dbId,
        collectionId: historyCollectionId,
        queries: [Query.equal('username', name)],
      );

      logger.i(
          "[Auth] _checkUsernameAvailability: Query completed. Found ${result.documents.length} documents with username '$name'");

      // Final input consistency check
      if (name != _currentCheckingUsername || name != usernameText.value) {
        logger.i(
            "[Auth] _checkUsernameAvailability: Name changed after query, aborting");
        return false;
      }

      // Username is available if no records found in history
      usernameAvailable.value = result.documents.isEmpty;

      if (usernameAvailable.value) {
        usernameError.value = '';
        logger.i(
            "[Auth] _checkUsernameAvailability: Username '$name' is AVAILABLE");
      } else {
        logger.i(
            "[Auth] _checkUsernameAvailability: Username '$name' is TAKEN (found in history)");
      }

      return usernameAvailable.value;
    } on AppwriteException catch (e) {
      logger.e(
          "[Auth] _checkUsernameAvailability: AppwriteException. Code: ${e.code}, Message: ${e.message}");
      final message = e.message ?? 'username_check_error'.tr;
      usernameError.value = message;
      Get.snackbar(
        'error'.tr,
        message,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 10),
      );
      usernameAvailable.value = false;
      return false;
    } catch (e) {
      logger.e("[Auth] _checkUsernameAvailability: Unknown error: $e");
      Get.snackbar(
        'error'.tr,
        'unexpected_error'.tr,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 10),
      );
      usernameAvailable.value = false;
      usernameError.value = 'unexpected_error'.tr;
      return false;
    } finally {
      isCheckingUsername.value = false;
      hasCheckedUsername.value = true;
      _currentCheckingUsername = null;
      logger.i(
          "[Auth] _checkUsernameAvailability: Finished checking username '$name'");
    }
  }

  Future<void> _addUsernameToHistory(String uid, String name,
      {String subscriptionType = 'Free'}) async {
    final dbId = dotenv.env[_databaseIdKey] ?? 'StarChat_DB';
    final historyCollectionId =
        dotenv.env[_usernamesHistoryCollectionKey] ?? 'user_names_history';

    logger.i(
        "[Auth] _addUsernameToHistory: Adding username '$name' to history for user '$uid'");
    logger.i(
        "[Auth] _addUsernameToHistory: Using dbId: '$dbId', historyCollectionId: '$historyCollectionId'");

    try {
      final docData = {
        'username': name,
        'userId': uid,
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
        'subscriptionType': subscriptionType,
      };

      logger.i(
          "[Auth] _addUsernameToHistory: Creating document with data: $docData");

      final doc = await databases.createDocument(
        databaseId: dbId,
        collectionId: historyCollectionId,
        documentId: ID.unique(),
        data: docData,
        permissions: [
          Permission.read(Role.user(uid)),
          Permission.update(Role.user(uid)),
          Permission.delete(Role.user(uid)),
        ],
      );

      logger.i(
          "[Auth] _addUsernameToHistory: Successfully added username '$name' to history. Document ID: ${doc.$id}");
    } catch (e) {
      logger.e(
          "[Auth] _addUsernameToHistory: Error adding username to history: $e");
      // Re-throw the error so the calling method can handle it
      rethrow;
    }
  }

  Future<void> _saveUsername(
      String dbId,
      String collectionId,
      String uid,
      String name,
      SharedPreferences prefs,
      {
      String? rashiId,
      String? nakshatraId,
      }) async {
    logger.i(
        "[Auth] _saveUsername: Starting save process for username '$name' and user '$uid'");
    logger.i(
        "[Auth] _saveUsername: Using dbId: '$dbId', collectionId: '$collectionId'");

    try {
      logger.i("[Auth] _saveUsername: STEP 1 - Adding username to history");
      await _addUsernameToHistory(uid, name);

      logger.i(
          "[Auth] _saveUsername: STEP 2 - Checking for existing user profile");
      final existing = await databases.listDocuments(
        databaseId: dbId,
        collectionId: collectionId,
        queries: [
          Query.equal('userId', uid),
          Query.limit(1),
        ],
      );

      final now = DateTime.now().toUtc().toIso8601String();

      if (existing.documents.isNotEmpty) {
        logger.i(
            "[Auth] _saveUsername: STEP 3A - Updating existing user profile");
        final docId = existing.documents.first.$id;

        await databases.updateDocument(
          databaseId: dbId,
          collectionId: collectionId,
          documentId: docId,
          data: {
            'username': name,
            'birth_rashi': rashiId ?? '',
            'birth_nakshatra': nakshatraId ?? '',
            'updatedAt': now,
          },
        );
        logger.i(
            "[Auth] _saveUsername: Successfully updated existing user profile with username '$name'");
      } else {
        logger.i("[Auth] _saveUsername: STEP 3B - Creating new user profile");

      final profileData = {
        'userId': uid,
        'username': name,
        'displayname': '',
        'profilePicture': '',
        'userType': 'General User',
          'firstName': '',
          'lastName': '',
          'birth_rashi': rashiId ?? '',
          'birth_nakshatra': nakshatraId ?? '',
          'createdAt': now,
          'updatedAt': now,
        };

        logger.i(
            "[Auth] _saveUsername: Creating profile with data: $profileData");

        final doc = await databases.createDocument(
          databaseId: dbId,
          collectionId: collectionId,
          documentId: ID.unique(),
          data: profileData,
          permissions: [
            Permission.read(Role.user(uid)),
            Permission.update(Role.user(uid)),
            Permission.delete(Role.user(uid)),
          ],
        );
        logger.i(
            "[Auth] _saveUsername: Successfully created new user profile. Document ID: ${doc.$id}");
      }

      logger.i("[Auth] _saveUsername: STEP 4 - Updating local state and cache");
      username.value = name;
      await prefs.setString('username', name);
      birthRashiId.value = rashiId ?? '';
      birthNakshatraId.value = nakshatraId ?? '';

      logger.i(
          "[Auth] _saveUsername: Successfully completed save process for username '$name'");
    } catch (e) {
      logger.e("[Auth] _saveUsername: Error in save process: $e");

      if (e is AppwriteException) {
        if (e.code == 409 ||
            e.message?.contains('duplicate') == true ||
            e.message?.contains('unique') == true) {
          logger.e(
              "[Auth] _saveUsername: Username '$name' is already taken (duplicate key error)");
          throw Exception('USERNAME_TAKEN');
        } else {
          logger.e(
              "[Auth] _saveUsername: AppwriteException during save. Code: ${e.code}, Message: ${e.message}");
          throw Exception('SAVE_ERROR: ${e.message}');
        }
      } else {
        logger.e("[Auth] _saveUsername: Unknown error during save: $e");
        throw Exception('SAVE_ERROR: $e');
      }
    }
  }

  void onUsernameChanged(String value) {
    usernameText.value = value;
    isUsernameValid.value = isValidUsername(value);
    usernameError.value = '';

    _usernameDebounce?.cancel();
    hasCheckedUsername.value = false;
    isCheckingUsername.value = false;

    if (!isUsernameValid.value || value.isEmpty) {
      usernameAvailable.value = false;
      _currentCheckingUsername = null;
      return;
    }

    _currentCheckingUsername = value;
    _usernameDebounce = Timer(usernameDebounceDuration, () {
      if (_currentCheckingUsername == value && value == usernameText.value) {
        _checkUsernameAvailability(value);
      }
    });
  }

  void clearUsernameInput() {
    usernameController.clear();
    isUsernameValid.value = false;
    usernameAvailable.value = false;
    usernameText.value = '';
    isCheckingUsername.value = false;
    usernameError.value = '';
    _usernameDebounce?.cancel();
  }

  Future<void> checkUsernameAvailability() async {
    final name = usernameController.text.trim();
    if (name.isEmpty) {
      usernameError.value = 'empty_username'.tr;
      Get.snackbar(
        'error'.tr,
        usernameError.value,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 10),
      );
      return;
    }
    if (!isValidUsername(name)) {
      usernameError.value = 'invalid_username_message'.tr;
      Get.snackbar(
        'error'.tr,
        usernameError.value,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 10),
      );
      return;
    }
    usernameError.value = '';
    hasCheckedUsername.value = false;
    _currentCheckingUsername = name;
    usernameText.value = name;
    await _checkUsernameAvailability(name);
  }

  Future<String?> fetchCurrentUserId() async {
    try {
      final session = await account.get();
      return session.$id;
    } catch (e) {
      logger.e('Error fetching user ID', error: e);
      return null;
    }
  }

  Future<void> submitUsername() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final name = usernameController.text.trim();
    logger.i("[Auth] submitUsername: Starting submission for username '$name'");

    if (!isValidUsername(name)) {
      usernameError.value = 'invalid_username_message'.tr;
      Get.snackbar(
        'error'.tr,
        usernameError.value,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 10),
      );
      return;
    }

    if (!hasCheckedUsername.value || !usernameAvailable.value) {
      logger.i(
          "[Auth] submitUsername: No recent availability check or username not available, checking now");
      usernameError.value = '';
      isLoading.value = true;

      try {
        final available = await _checkUsernameAvailability(name);
        if (!available) {
          isLoading.value = false;
          usernameError.value = 'username_taken'.tr;
          Get.snackbar(
            'error'.tr,
            usernameError.value,
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 10),
          );
          return;
        }
      } catch (e) {
        isLoading.value = false;
        logger.e("[Auth] submitUsername: Error during availability check: $e");
        usernameError.value = 'username_check_error'.tr;
        Get.snackbar(
          'error'.tr,
          usernameError.value,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 10),
        );
        return;
      }
    } else {
      logger.i(
          "[Auth] submitUsername: Username '$name' was already checked and is available, proceeding with save");
      isLoading.value = true;
    }

    usernameError.value = '';

    try {
      final prefs = await SharedPreferences.getInstance();
      final dbId = dotenv.env[_databaseIdKey] ?? 'StarChat_DB';
      final collectionId =
          dotenv.env[_profilesCollectionKey] ?? 'user_profiles';
      final session = await account.get();
      final uid = session.$id;

      logger.i(
          "[Auth] submitUsername: Calling _saveUsername for user '$uid' with username '$name'");
      await _saveUsername(
        dbId,
        collectionId,
        uid,
        name,
        prefs,
        rashiId: birthRashiId.value,
        nakshatraId: birthNakshatraId.value,
      );

      isLoading.value = false;
      logger.i("[Auth] submitUsername: Successfully saved username '$name'");

      // Always proceed to the home screen after successfully saving the
      // username. Previously the navigation depended on `Get.previousRoute`,
      // which could keep the user on the username page if the route history
      // wasn't cleared correctly.
      Get.offAllNamed('/home');
    } catch (e) {
      isLoading.value = false;
      logger.e("[Auth] submitUsername: Error during username save: $e");

      if (e.toString().contains('USERNAME_TAKEN')) {
        usernameError.value = 'username_taken'.tr;
        usernameAvailable.value = false;
        hasCheckedUsername.value = false;
        Get.snackbar(
          'error'.tr,
          usernameError.value,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 10),
        );
      } else if (e.toString().contains('SAVE_ERROR')) {
        usernameError.value = 'Failed to save username. Please try again.';
        Get.snackbar(
          'error'.tr,
          usernameError.value,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 10),
        );
      } else {
        usernameError.value = 'unexpected_error'.tr;
        Get.snackbar(
          'error'.tr,
          usernameError.value,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 10),
        );
      }
    }
  }

  Future<void> deleteUsername() async {
    isLoading.value = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final dbId = dotenv.env[_databaseIdKey] ?? 'StarChat_DB';
      final collectionId =
          dotenv.env[_profilesCollectionKey] ?? 'user_profiles';
      final session = await account.get();
      final uid = session.$id;
      final result = await databases.listDocuments(
        databaseId: dbId,
        collectionId: collectionId,
        queries: [
          Query.equal('userId', uid),
          Query.limit(1),
        ],
      );
      if (result.documents.isNotEmpty) {
        await databases.updateDocument(
          databaseId: dbId,
          collectionId: collectionId,
          documentId: result.documents.first.$id,
          data: {
            'username': '',
            'updatedAt': DateTime.now().toUtc().toIso8601String(),
          },
        );
      }
      username.value = "";
      await prefs.remove("username");
      await ensureUsername();
      Get.snackbar('success'.tr, 'username_deleted'.tr,
          snackPosition: SnackPosition.BOTTOM);
    } on AppwriteException catch (e) {
      logger.e('Error deleting username', error: e);
      Get.snackbar('error'.tr, 'failed_to_delete_username'.tr,
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      logger.e('Unknown error deleting username', error: e);
      Get.snackbar('error'.tr, 'unexpected_error'.tr,
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteUserAccount() async {
    isLoading.value = true;
    try {
      await account.updateStatus();
      logger.i('Account deleted successfully');
      clearControllers();
      isOTPSent.value = false;
      Get.offAllNamed('/');
      Get.snackbar(
        'success'.tr,
        'account_deleted'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } on AppwriteException catch (e) {
      logger.e('Error deleting account', error: e);
      Get.snackbar(
        'error'.tr,
        'failed_to_delete_account'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      logger.e('Unknown error deleting account', error: e);
      Get.snackbar(
        'error'.tr,
        'unexpected_error'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    isLoading.value = true;
    String? uid;
    try {
      final session = await account.get();
      uid = session.$id;
      await account.deleteSessions();
    } catch (e) {
      logger.e('Error deleting Appwrite session(s)', error: e);
    } finally {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('username');
        await prefs.remove('displayname');
        await prefs.remove(UserTypeController.storageKey);
        if (uid != null) {
          await prefs.remove('watchlist_items_$uid');
        }
        // Reset local user type to default on logout
        try {
          final userTypeController = Get.find<UserTypeController>();
          await userTypeController.applyUserType('General User');
        } catch (_) {}
      } catch (e) {
        logger.e('Error clearing cached username from SharedPreferences',
            error: e);
      }

      clearControllers();

      isOTPSent.value = false;
      username.value = '';
      displayName.value = '';
      profilePictureUrl.value = '';
      userId = null;

      isCheckingUsername.value = false;
      usernameAvailable.value = false;
      hasCheckedUsername.value = false;
      isUsernameValid.value = false;

      canResendOTP.value = true;
      resendCooldown.value = resendCooldownDuration;
      otpExpiration.value = otpExpirationDuration;

      cancelTimers();

      justLoggedOut.value = true;
      isLoading.value = false;
      Get.offAllNamed('/logged-out');
    }
  }

  Future<void> updateProfilePicture(File file) async {
    isLoading.value = true;
    final bucketId = dotenv.env[_bucketIdKey] ?? 'profile_pics';
    final dbId = dotenv.env[_databaseIdKey] ?? 'StarChat_DB';
    final collectionId = dotenv.env[_profilesCollectionKey] ?? 'user_profiles';
    try {
      final session = await account.get();
      final uid = session.$id;
      final upload = await storage.createFile(
        bucketId: bucketId,
        fileId: ID.unique(),
        file: InputFile.fromPath(path: file.path),
      );
      final url =
          '${client.endPoint}/storage/buckets/$bucketId/files/${upload.$id}/view?project=${client.config['project']}';
      final result = await databases.listDocuments(
        databaseId: dbId,
        collectionId: collectionId,
        queries: [
          Query.equal('userId', uid),
          Query.limit(1),
        ],
      );
      if (result.documents.isNotEmpty) {
        final docId = result.documents.first.$id;
        await databases.updateDocument(
          databaseId: dbId,
          collectionId: collectionId,
          documentId: docId,
          data: {'profilePicture': url},
        );
        profilePictureUrl.value = url;
      }
    } catch (e) {
      logger.e('Error updating profile picture', error: e);
      Get.snackbar('error'.tr, 'unexpected_error'.tr,
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<Map<String, dynamic>>> getUsernameHistory() async {
    try {
      final session = await account.get();
      final uid = session.$id;
      final dbId = dotenv.env[_databaseIdKey] ?? 'StarChat_DB';
      final historyCollectionId =
          dotenv.env[_usernamesHistoryCollectionKey] ?? 'user_names_history';

      final result = await databases.listDocuments(
        databaseId: dbId,
        collectionId: historyCollectionId,
        queries: [
          Query.equal('userId', uid),
          Query.orderDesc('createdAt'),
        ],
      );

      return result.documents.map((doc) => doc.data).toList();
    } catch (e) {
      logger.e('Error fetching username history', error: e);
      return [];
    }
  }

  /// Update the user type on the server and locally.
  Future<void> updateUserType(String type) async {
    isLoading.value = true;
    final dbId = dotenv.env[_databaseIdKey] ?? 'StarChat_DB';
    final collectionId = dotenv.env[_profilesCollectionKey] ?? 'user_profiles';
    try {
      final session = await account.get();
      final uid = session.$id;
      final result = await databases.listDocuments(
        databaseId: dbId,
        collectionId: collectionId,
        queries: [
          Query.equal('userId', uid),
          Query.limit(1),
        ],
      );
      if (result.documents.isNotEmpty) {
        final docId = result.documents.first.$id;
        await databases.updateDocument(
          databaseId: dbId,
          collectionId: collectionId,
          documentId: docId,
          data: {
            'userType': type,
            'updatedAt': DateTime.now().toUtc().toIso8601String(),
          },
        );
      }

      final userTypeController = Get.find<UserTypeController>();
      await userTypeController.updateUserType(type);
    } catch (e) {
      logger.e('Error updating user type', error: e);
      Get.snackbar('error'.tr, 'unexpected_error'.tr,
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateDisplayName(String name) async {
    isLoading.value = true;
    final dbId = dotenv.env[_databaseIdKey] ?? 'StarChat_DB';
    final collectionId = dotenv.env[_profilesCollectionKey] ?? 'user_profiles';
    try {
      final session = await account.get();
      final uid = session.$id;
      final result = await databases.listDocuments(
        databaseId: dbId,
        collectionId: collectionId,
        queries: [
          Query.equal('userId', uid),
          Query.limit(1),
        ],
      );
      if (result.documents.isNotEmpty) {
        final docId = result.documents.first.$id;
        await databases.updateDocument(
          databaseId: dbId,
          collectionId: collectionId,
          documentId: docId,
          data: {
            'displayname': name,
            'updatedAt': DateTime.now().toUtc().toIso8601String(),
          },
        );
      }
      displayName.value = name;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('displayname', name);
    } catch (e) {
      logger.e('Error updating display name', error: e);
      Get.snackbar('error'.tr, 'unexpected_error'.tr,
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }
}
