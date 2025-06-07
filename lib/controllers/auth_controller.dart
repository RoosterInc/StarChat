import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:appwrite/appwrite.dart';
import 'package:logger/logger.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:email_validator/email_validator.dart'; // Added for email validation
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:collection/collection.dart'; // Added for firstWhereOrNull
import 'multi_account_controller.dart';

class AuthController extends GetxController {
  final Client client = Client();
  late Account account;
  late Databases databases;
  late Storage storage;

  final isLoading = false.obs;
  final isOTPSent = false.obs;
  final justLoggedOut = false.obs;
  final isCheckingUsername = false.obs;
  final usernameAvailable = false.obs;
  final hasCheckedUsername = false.obs;
  final username = ''.obs;
  final profilePictureUrl = ''.obs;
  final isUsernameValid = false.obs;
  final usernameText = ''.obs;
  final emailError = ''.obs;
  final otpError = ''.obs;
  final usernameError = ''.obs;
  Timer? _usernameDebounce;
  static const Duration usernameDebounceDuration = Duration(milliseconds: 500);
  late TextEditingController usernameController;

  late TextEditingController emailController;
  late TextEditingController otpController;

  String? userId;

  final logger = Logger();

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

    checkExistingSession();
  }

  @override
  void onClose() {
    emailController.clear();
    otpController.clear();
    usernameController.clear();
    usernameText.value = '';
    emailError.value = '';
    otpError.value = '';
    usernameError.value = '';
    cancelTimers();
    super.onClose();
  }

  Future<void> checkExistingSession({String? userIdToSwitchTo}) async {
    isLoading.value = true;
    logger.i("[Auth] checkExistingSession: Called. userIdToSwitchTo: $userIdToSwitchTo, justLoggedOut: ${justLoggedOut.value}");

    if (justLoggedOut.value) {
      justLoggedOut.value = false;
      logger.i("[Auth] checkExistingSession: 'justLoggedOut' flag was true. Short-circuiting. Current route should be '/'.");
      isLoading.value = false;
      if (Get.currentRoute != '/') Get.offAllNamed('/');
      return;
    }

    String? targetAppwriteUserId;
    final multiAccountController = Get.find<MultiAccountController>();

    if (userIdToSwitchTo != null) {
      targetAppwriteUserId = userIdToSwitchTo;
      logger.i("[Auth] checkExistingSession: Explicit userIdToSwitchTo provided: $targetAppwriteUserId");
    } else {
      final activeUserFromMultiAccount = multiAccountController.activeAccountId.value;
      if (activeUserFromMultiAccount.isNotEmpty) {
        targetAppwriteUserId = activeUserFromMultiAccount;
        logger.i("[Auth] checkExistingSession: Using active user from MultiAccountController: $targetAppwriteUserId");
      }
    }

    Models.Session? currentAppwriteSession;
    try {
      currentAppwriteSession = await account.get().catchError((e) {
        logger.i('[Auth] checkExistingSession: Error getting current Appwrite session (initial check): $e');
        return null;
      });
    } catch (e) {
      logger.i('[Auth] checkExistingSession: Exception during initial account.get(): $e');
      currentAppwriteSession = null; // Ensure it's null on any error
    }


    if (targetAppwriteUserId == null || targetAppwriteUserId.isEmpty) {
      logger.i("[Auth] checkExistingSession: No targetAppwriteUserId determined yet.");
      if (currentAppwriteSession != null) {
        logger.i("[Auth] checkExistingSession: Found an existing Appwrite session (${currentAppwriteSession.$userId}) not tracked by MultiAccountController or no specific user was targeted. Using this session.");
        targetAppwriteUserId = currentAppwriteSession.$userId;
        // Potentially add this user to MultiAccountController if we had their token generation details.
        // For now, we just proceed with this session. If it's not in multiAccountController,
        // switching away from it might require re-login for this specific account.
        // We should also check if this account IS in multiAccountController and just wasn't active.
        final existingAccountInfo = multiAccountController.accounts.firstWhereOrNull((acc) => acc.appwriteUserId == targetAppwriteUserId);
        if (existingAccountInfo != null && existingAccountInfo.currentSessionId != currentAppwriteSession.$id) {
          // Update session ID in multi-account store
          final updatedAcc = AccountInfo(
              appwriteUserId: existingAccountInfo.appwriteUserId,
              username: existingAccountInfo.username,
              email: existingAccountInfo.email,
              tokenGenerationUserId: existingAccountInfo.tokenGenerationUserId,
              tokenSecret: existingAccountInfo.tokenSecret,
              profilePictureUrl: existingAccountInfo.profilePictureUrl,
              currentSessionId: currentAppwriteSession.$id);
          await multiAccountController.addAccount(updatedAcc);
        }
      } else {
        logger.i("[Auth] checkExistingSession: No active Appwrite session and no target user from multi-account. Navigating to sign-in.");
        Get.offAllNamed('/');
        isLoading.value = false;
        return;
      }
    }

    // Re-fetch current session info if not already done, or if it might have changed.
    // This might be redundant if the first account.get() was successful and targetAppwriteUserId was derived from it.
    // However, if targetAppwriteUserId came from multiAccountController, we need to be sure.
    if (currentAppwriteSession == null || currentAppwriteSession.$userId != targetAppwriteUserId) {
        try {
            currentAppwriteSession = await account.get().catchError((e) {
                logger.i('[Auth] checkExistingSession: Error getting current Appwrite session (pre-switch check): $e');
                return null;
            });
        } catch (e) {
            logger.i('[Auth] checkExistingSession: Exception during account.get() (pre-switch check): $e');
            currentAppwriteSession = null;
        }
    }


    if (currentAppwriteSession != null && currentAppwriteSession.$userId == targetAppwriteUserId) {
      logger.i('[Auth] checkExistingSession: Correct session already active for $targetAppwriteUserId.');
      // Ensure MultiAccountController also knows this session is active if it wasn't before
      final accInfo = multiAccountController.accounts.firstWhereOrNull((a) => a.appwriteUserId == targetAppwriteUserId);
      if (accInfo != null && accInfo.currentSessionId != currentAppwriteSession.$id) {
          final updatedAcc = AccountInfo(
              appwriteUserId: accInfo.appwriteUserId,
              username: accInfo.username,
              email: accInfo.email,
              tokenGenerationUserId: accInfo.tokenGenerationUserId,
              tokenSecret: accInfo.tokenSecret,
              profilePictureUrl: accInfo.profilePictureUrl,
              currentSessionId: currentAppwriteSession.$id);
          await multiAccountController.addAccount(updatedAcc);
      }
      // Proceed with ensuring username and navigation
    } else {
      logger.i('[Auth] checkExistingSession: Session switch needed. Target: $targetAppwriteUserId. Current SDK session: ${currentAppwriteSession?.$userId}');
      if (currentAppwriteSession != null) {
        logger.i('[Auth] checkExistingSession: Clearing existing session for ${currentAppwriteSession.$userId}.');
        try {
          await account.deleteSession(sessionId: 'current');
          logger.i('[Auth] checkExistingSession: Successfully deleted current session.');
        } catch (e) {
          logger.e('[Auth] checkExistingSession: Failed to delete current session: $e. Proceeding with switch attempt.');
        }
        currentAppwriteSession = null; // Session is now invalid
      }

      final accountInfoToSwitch = multiAccountController.accounts.firstWhereOrNull((acc) => acc.appwriteUserId == targetAppwriteUserId);

      if (accountInfoToSwitch == null ||
          accountInfoToSwitch.tokenGenerationUserId.isEmpty ||
          accountInfoToSwitch.tokenSecret.isEmpty) {
        logger.e('[Auth] checkExistingSession: Account info not found or incomplete for $targetAppwriteUserId. Cannot switch. Navigating to sign-in.');
        if (userIdToSwitchTo != null) {
          Get.snackbar('Error', 'Failed to switch account. Please try logging in again.');
        }
        await multiAccountController.removeAccount(targetAppwriteUserId!); // Remove potentially corrupt/incomplete account
        Get.offAllNamed('/');
        isLoading.value = false;
        return;
      }

      logger.i('[Auth] checkExistingSession: Attempting to create session for ${accountInfoToSwitch.appwriteUserId} using stored token info (token user ID: ${accountInfoToSwitch.tokenGenerationUserId}).');
      try {
        final newSession = await account.createSession(
          userId: accountInfoToSwitch.tokenGenerationUserId,
          secret: accountInfoToSwitch.tokenSecret,
        );
        logger.i('[Auth] checkExistingSession: Successfully created new session for ${newSession.$userId}. New session ID: ${newSession.$id}');

        final updatedAccountInfo = AccountInfo(
          appwriteUserId: accountInfoToSwitch.appwriteUserId,
          username: accountInfoToSwitch.username, // Preserve existing username
          email: accountInfoToSwitch.email,
          tokenGenerationUserId: accountInfoToSwitch.tokenGenerationUserId,
          tokenSecret: accountInfoToSwitch.tokenSecret,
          profilePictureUrl: accountInfoToSwitch.profilePictureUrl, // Preserve existing pic
          currentSessionId: newSession.$id,
        );
        await multiAccountController.addAccount(updatedAccountInfo); // This updates and saves
        multiAccountController.activeAccountId.value = newSession.$userId; // Explicitly set active
        await multiAccountController.sendDataToWatch(); // Notify watch

      } on AppwriteException catch (e) {
        logger.e('[Auth] checkExistingSession: AppwriteException during createSession for $targetAppwriteUserId: ${e.message} (Code: ${e.code})');
        if (e.code == 401 || e.code == 403 || (e.message != null && e.message!.toLowerCase().contains("user_not_found"))) { // 404 for user_not_found might also be relevant
          logger.w('[Auth] checkExistingSession: Invalid token/secret or user not found for $targetAppwriteUserId. Removing account from multi-account list.');
          await multiAccountController.removeAccount(targetAppwriteUserId);
        }
        Get.offAllNamed('/');
        isLoading.value = false;
        return;
      } catch (e) {
        logger.e('[Auth] checkExistingSession: Generic error during createSession for $targetAppwriteUserId: $e');
        Get.offAllNamed('/');
        isLoading.value = false;
        return;
      }
    }

    // Common final steps: ensure username and navigate
    try {
      bool hasUsername = await ensureUsername(); // ensureUsername should use the new session context
      if (hasUsername) {
        logger.i("[Auth] checkExistingSession: User has username. Current route: ${Get.currentRoute}");
        if (Get.currentRoute == '/' || Get.currentRoute == '/set_username') {
          logger.i("[Auth] checkExistingSession: Navigating to /home");
          Get.offAllNamed('/home');
        } else {
          logger.i("[Auth] checkExistingSession: Already on an authenticated route (${Get.currentRoute}), not navigating further from checkExistingSession.");
        }
      } else {
        logger.i("[Auth] checkExistingSession: User does NOT have username. Current route: ${Get.currentRoute}");
        if (Get.currentRoute != '/set_username') {
          logger.i("[Auth] checkExistingSession: Navigating to /set_username");
          Get.offAllNamed('/set_username');
        } else {
          logger.i("[Auth] checkExistingSession: Already on /set_username, not navigating.");
        }
      }
    } catch (e) {
        logger.e("[Auth] checkExistingSession: Error during ensureUsername or navigation: $e");
        Get.offAllNamed('/'); // Fallback to sign-in on error
    } finally {
        isLoading.value = false;
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
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      Get.snackbar(
        'no_internet'.tr,
        'check_internet'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isLoading.value = true;
    try {
      final result = await account
          .createEmailToken(
            userId: ID.unique(), // This is the tokenGenerationUserId
            email: email,
          )
          .timeout(const Duration(seconds: 15));

      // Store these details temporarily for verifyOTP, they will be saved permanently
      // into AccountInfo by verifyOTP after successful session creation.
      _tempTokenGenerationUserId = result.userId;
      _tempTokenSecret = result.secret; // Storing the secret from createEmailToken
      _tempEmail = email; // Storing the email

      // userId = result.userId; // This 'userId' was ambiguous.
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
    } on TimeoutException {
      Get.snackbar(
        'error'.tr,
        'request_timeout'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
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

    isLoading.value = true;
    try {
      await account.get();
      await Get.offAllNamed('/home');
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
        // final session = await account.createSession( // Original
        //   userId: userId!, // This should be _tempTokenGenerationUserId
        //   secret: otp, // This is correct, it's the OTP from the user
        // );
        if (_tempTokenGenerationUserId == null || _tempTokenSecret == null) {
          logger.e('verifyOTP: Temporary token generation details are missing.');
          Get.snackbar('Error', 'An internal error occurred. Please try sending OTP again.');
          isLoading.value = false;
          return;
        }

        final session = await account.createSession(
          userId: _tempTokenGenerationUserId!, // Use the ID from createEmailToken
          secret: otp, // Use the OTP entered by the user
        );

        logger.i("[Auth] verifyOTP: Session created successfully for Appwrite User ID: ${session.$userId}, using Token Generation User ID: $_tempTokenGenerationUserId");

        otpError.value = '';
        // After session creation, persist this account to MultiAccountController
        // Use session.$userId as the appwriteUserId
        // Use _tempTokenGenerationUserId and _tempTokenSecret for session recreation
        final newAccountInfo = AccountInfo(
          appwriteUserId: session.$userId, // This is the actual Appwrite User ID
          username: '', // Username will be set by ensureUsername/setUsername flow
          email: _tempEmail ?? '', // Email used for OTP
          tokenGenerationUserId: _tempTokenGenerationUserId!, // ID used for createEmailToken
          tokenSecret: _tempTokenSecret!, // Secret from createEmailToken
          currentSessionId: session.$id, // Current active session ID
          profilePictureUrl: '', // Will be set later
        );
        final multiAccountController = Get.find<MultiAccountController>();
        await multiAccountController.addAccount(newAccountInfo);
        multiAccountController.activeAccountId.value = session.$userId; // Set as active
        await multiAccountController.sendDataToWatch(); // Notify watch


        bool hasUsername = await ensureUsername(); // This will now use the new session context

        if (hasUsername) {
          // Update username in AccountInfo if ensureUsername found one
          final updatedAccWithUsername = AccountInfo(
            appwriteUserId: newAccountInfo.appwriteUserId,
            username: this.username.value, // Updated username
            email: newAccountInfo.email,
            tokenGenerationUserId: newAccountInfo.tokenGenerationUserId,
            tokenSecret: newAccountInfo.tokenSecret,
            currentSessionId: newAccountInfo.currentSessionId,
            profilePictureUrl: this.profilePictureUrl.value, // Updated profile picture
          );
          await multiAccountController.addAccount(updatedAccWithUsername);
          await Get.offAllNamed('/home');
        } else {
          await Get.offAllNamed('/set_username');
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

  void exitSignIn() {
    cancelTimers();
    clearControllers();
    isOTPSent.value = false;
    isLoading.value = false;
    if (Get.previousRoute.isNotEmpty) {
      Get.back();
    } else {
      Get.offAllNamed('/accounts');
    }
  }

  void cancelTimers() {
    _resendTimer?.cancel();
    _otpTimer?.cancel();
  }

  void clearControllers() {
    emailController.clear();
    otpController.clear();
    usernameController.clear();
    usernameText.value = '';
    cancelTimers();
  }

  Future<bool> ensureUsername() async {
    logger.i("[Auth] ensureUsername: Called. Current local userId: ${this.userId}, Current local username: ${username.value}");

    final prefs = await SharedPreferences.getInstance();
    final dbId = dotenv.env[_databaseIdKey] ?? 'StarChat_DB';
    final collectionId = dotenv.env[_profilesCollectionKey] ?? 'user_profiles';

    try {
      final session = await account.get();
      final uid = session.$id;
      logger.i("[Auth] ensureUsername: Fetched session successfully. User ID for query: $uid, Email: ${session.email}");

      final result = await databases.listDocuments(
        databaseId: dbId,
        collectionId: collectionId,
        queries: [
          Query.equal('userId', uid),
          Query.orderDesc('createdAt'),
          Query.limit(1),
        ],
      );
      logger.i("[Auth] ensureUsername: Database query for userId '$uid' found ${result.documents.length} documents.");

      if (result.documents.isNotEmpty) {
        final data = result.documents.first.data;
        final fetchedUsername = data['username'];
        logger.i("[Auth] ensureUsername: Document found. Username from DB: '$fetchedUsername'. Profile Pic URL: '${data['profilePicture']}'");
        if (fetchedUsername != null && fetchedUsername != '') {
          username.value = fetchedUsername;
          if (data['profilePicture'] != null && data['profilePicture'] != '') {
            profilePictureUrl.value = data['profilePicture'];
          }
          await prefs.setString('username', username.value);
          logger.i("[Auth] ensureUsername: Returning true (username found and set).");
          return true;
        } else {
          logger.i("[Auth] ensureUsername: Document found but username is null or empty in DB.");
        }
      } else {
        logger.i("[Auth] ensureUsername: No document found in DB for userId '$uid'.");
      }

      await prefs.remove('username');
      username.value = '';
      profilePictureUrl.value = '';
      logger.i("[Auth] ensureUsername: Returning false (no username found on server for this session/UID, or it was empty).");
      return false;
    } catch (e) {
      if (e is AppwriteException) {
        logger.e("[Auth] ensureUsername: AppwriteException. Code: ${e.code}, Message: ${e.message}");
      } else {
        logger.e("[Auth] ensureUsername: General error: $e");
      }

      final cachedName = prefs.getString('username');
      logger.i("[Auth] ensureUsername: Attempting fallback to cached username. Cached name: '$cachedName'");
      if (cachedName != null) {
        username.value = cachedName;
        logger.i("[Auth] ensureUsername: Returning true (using cached username due to server error).");
        return true;
      }

      logger.i("[Auth] ensureUsername: Returning false (error and no cached username).");
      return false;
    }
  }

  Future<void> _promptForUsername(
      String dbId, String collectionId, String uid, SharedPreferences prefs) async {
    final textController = TextEditingController();
    usernameAvailable.value = false;

    await Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('enter_username'.tr),
            content: Obx(() {
              final children = <Widget>[
                TextField(
                  controller: textController,
                  decoration: InputDecoration(
                    labelText: 'username'.tr,
                    suffixIcon: textController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              textController.clear();
                              usernameAvailable.value = false;
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) async {
                    setState(() {});
                    await _checkUsernameAvailability(value);
                  },
                ),
              ];

              if (textController.text.isNotEmpty) {
                children.add(const SizedBox(height: 8));
                if (isCheckingUsername.value) {
                  children.add(const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ));
                } else {
                  final available = isValidUsername(textController.text) &&
                      usernameAvailable.value;
                  children.add(Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        available ? Icons.check : Icons.close,
                        color: available ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        available
                            ? 'username_available'.tr
                            : 'username_taken'.tr,
                        style: TextStyle(
                          color: available ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ));
                }
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              );
            }),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: Text('cancel'.tr),
              ),
              Obx(() => ElevatedButton(
                    onPressed: usernameAvailable.value
                        ? () async {
                            await _saveUsername(
                                dbId, collectionId, uid, textController.text, prefs);
                            Get.back();
                          }
                        : null,
                    child: Text('save'.tr),
                  )),
            ],
          );
        },
      ),
      barrierDismissible: false,
    );
  }

  Future<bool> _checkUsernameAvailability(String name) async {
    if (name.isEmpty) {
      usernameAvailable.value = false;
      isCheckingUsername.value = false;
      return false;
    }
    isCheckingUsername.value = true;
    final dbId = dotenv.env[_databaseIdKey] ?? 'StarChat_DB';
    final collectionId = dotenv.env[_profilesCollectionKey] ?? 'user_profiles';
    try {
      final result = await databases.listDocuments(
        databaseId: dbId,
        collectionId: collectionId,
        queries: [Query.equal('username', name)],
      );
      usernameAvailable.value = result.documents.isEmpty;
      if (usernameAvailable.value) {
        usernameError.value = '';
      }
      return usernameAvailable.value;
    } on AppwriteException catch (e) {
      logger.e('AppwriteException checking username', error: e);
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
      logger.e('Unknown error checking username', error: e);
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
    }
  }

  Future<void> _saveUsername(String dbId, String collectionId, String uid,
      String name, SharedPreferences prefs) async {
    try {
      final existing = await databases.listDocuments(
        databaseId: dbId,
        collectionId: collectionId,
        queries: [
          Query.equal('userId', uid),
          Query.orderDesc('createdAt'),
          Query.limit(1),
        ],
      );
      if (existing.documents.isNotEmpty) {
        await databases.updateDocument(
          databaseId: dbId,
          collectionId: collectionId,
          documentId: existing.documents.first.$id,
          data: {
            'username': name,
            'UpdateAt': DateTime.now().toUtc().toIso8601String(),
          },
        );
      } else {
        await databases.createDocument(
          databaseId: dbId,
          collectionId: collectionId,
          documentId: ID.unique(),
          data: {
            'userId': uid,
            'username': name,
            'profilePicture': '',
            'firstName': '',
            'lastName': '',
            'createdAt': DateTime.now().toUtc().toIso8601String(),
            'UpdateAt': DateTime.now().toUtc().toIso8601String(),
          },
          permissions: [
            Permission.read(Role.user(uid)),
            Permission.update(Role.user(uid)),
            Permission.delete(Role.user(uid)),
          ],
        );
      }
      username.value = name;
      await prefs.setString('username', name);
    } catch (e) {
      logger.e('Error saving username', error: e);
    }
  }

  void onUsernameChanged(String value) {
    usernameText.value = value;
    isUsernameValid.value = isValidUsername(value);
    usernameError.value = '';
    _usernameDebounce?.cancel();
    hasCheckedUsername.value = false;
    if (!isUsernameValid.value) {
      usernameAvailable.value = false;
      isCheckingUsername.value = false;
      return;
    }
    isCheckingUsername.value = true;
    _usernameDebounce = Timer(usernameDebounceDuration, () {
      _checkUsernameAvailability(value);
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
    final name = usernameController.text.trim();
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
    isLoading.value = true;
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
    final prefs = await SharedPreferences.getInstance();
    final dbId = dotenv.env[_databaseIdKey] ?? 'StarChat_DB';
    final collectionId = dotenv.env[_profilesCollectionKey] ?? 'user_profiles';
    final session = await account.get();
    final uid = session.$id;
    await _saveUsername(dbId, collectionId, uid, name, prefs);
    isLoading.value = false;
    if (Get.previousRoute.isEmpty) {
      Get.offAllNamed('/home');
    } else {
      Get.back();
    }
  }

  Future<void> deleteUsername() async {
    isLoading.value = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final dbId = dotenv.env[_databaseIdKey] ?? 'StarChat_DB';
      final collectionId = dotenv.env[_profilesCollectionKey] ?? 'user_profiles';
      final session = await account.get();
      final uid = session.$id;
      final result = await databases.listDocuments(
        databaseId: dbId,
        collectionId: collectionId,
        queries: [
          Query.equal('userId', uid),
          Query.orderDesc('createdAt'),
          Query.limit(1),
        ],
      );
      if (result.documents.isNotEmpty) {
        final docId = result.documents.first.$id;
        await databases.deleteDocument(
          databaseId: dbId,
          collectionId: collectionId,
          documentId: docId,
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
    try {
      await account.deleteSessions();
    } catch (e) {
      logger.e('Error deleting Appwrite session(s)', error: e);
    } finally {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('username'); // Clear general username cache if any
      } catch (e) {
        logger.e('Error clearing cached username from SharedPreferences', error: e);
      }

      // Determine which account is being logged out
      String? loggedOutAppwriteUserId;
      try {
        // Attempt to get current session to identify user before deleting sessions
        final session = await account.get().catchError((_) => null);
        loggedOutAppwriteUserId = session?.$userId;
      } catch (_) { /* Ignore errors here */ }

      try {
        await account.deleteSessions(); // Delete all sessions for the current user context
        logger.i("[Auth] logout: All Appwrite sessions deleted.");
      } catch (e) {
        logger.e('[Auth] logout: Error deleting Appwrite session(s)', error: e);
      }

      clearControllers(); // Clears email/OTP controllers etc.

      isOTPSent.value = false; // Reset OTP state
      username.value = ''; // Clear local username cache
      profilePictureUrl.value = ''; // Clear local profile pic cache

      // userId = null; // This was the old ambiguous userId, ensure it's cleared or handled if still used elsewhere.
      // For multi-account, the active user is managed by MultiAccountController.
      // We need to inform MultiAccountController that this user is logged out.
      final multiAccountController = Get.find<MultiAccountController>();
      if (loggedOutAppwriteUserId != null) {
        logger.i("[Auth] logout: User $loggedOutAppwriteUserId logged out. Updating MultiAccountController.");
        // Option 1: Just clear the active session ID for this account
        final accInfo = multiAccountController.accounts.firstWhereOrNull((a) => a.appwriteUserId == loggedOutAppwriteUserId);
        if (accInfo != null) {
          final updatedAcc = AccountInfo(
            appwriteUserId: accInfo.appwriteUserId,
            username: accInfo.username,
            email: accInfo.email,
            tokenGenerationUserId: accInfo.tokenGenerationUserId,
            tokenSecret: accInfo.tokenSecret, // Keep token info for potential re-login
            profilePictureUrl: accInfo.profilePictureUrl,
            currentSessionId: null, // Mark session as inactive
          );
          await multiAccountController.addAccount(updatedAcc);
        }
        // Option 2: Or remove the account entirely if logout means "forget this account on this device"
        // await multiAccountController.removeAccount(loggedOutAppwriteUserId);
        // For now, let's go with Option 1 (marking session inactive)

        if (multiAccountController.activeAccountId.value == loggedOutAppwriteUserId) {
            multiAccountController.activeAccountId.value = ''; // Clear active account ID
        }
        await multiAccountController.sendDataToWatch(); // Notify watch
      } else {
        logger.w("[Auth] logout: Could not determine Appwrite User ID at logout. Active account in MultiAccountController might be stale.");
        // Potentially clear multiAccountController.activeAccountId.value if it's non-empty
        // but this case should ideally not happen if a session was active.
      }


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
      Get.offAllNamed('/');
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
          Query.orderDesc('createdAt'),
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
}
