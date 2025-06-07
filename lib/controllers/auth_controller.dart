import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:logger/logger.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:email_validator/email_validator.dart'; // Added for email validation
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../core/constants/app_constants.dart';

class AuthController extends GetxController {
  final Client client = Client();
  // Remove direct Appwrite SDK instances
  // late Account account;
  // late Databases databases;
  // late Storage storage;

  late AuthService _authService;
  late UserService _userService;

  final isLoading = false.obs;
  final isOTPSent = false.obs;
  final isCheckingUsername = false.obs;
  final usernameAvailable = false.obs;
  final hasCheckedUsername = false.obs;
  final username = ''.obs;
  final profilePictureUrl = ''.obs;
  final isUsernameValid = false.obs;
  final usernameText = ''.obs;
  Timer? _usernameDebounce;
  // static const Duration usernameDebounceDuration = Duration(milliseconds: 500); // Replaced by AppConstants
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
  // static const int resendCooldownDuration = 60; // Replaced by AppConstants
  // static const int otpExpirationDuration = 300; // Replaced by AppConstants

  // Environment variable keys
  // static const String _endpointKey = 'APPWRITE_ENDPOINT'; // Replaced by AppConstants
  // static const String _projectIdKey = 'APPWRITE_PROJECT_ID'; // Replaced by AppConstants
  // Keys for database, collection, bucket are now managed by UserService
  // static const String _databaseIdKey = 'APPWRITE_DATABASE_ID';
  // static const String _profilesCollectionKey = 'USER_PROFILES_COLLECTION_ID';
  // static const String _bucketIdKey = 'PROFILE_PICTURES_BUCKET_ID';

  @override
  void onInit() {
    super.onInit();
    final endpoint = dotenv.env[AppConstants.appwriteEndpointKey] ?? AppConstants.defaultAppwriteEndpoint;
    final projectId = dotenv.env[AppConstants.appwriteProjectIdKey] ?? AppConstants.defaultAppwriteProjectId;
    client.setEndpoint(endpoint).setProject(projectId); // Initialize the class member client

    _authService = AuthService(account: Account(client)); // Use the class member client
    _userService = UserService(
        databases: Databases(client), // Use the class member client
        storage: Storage(client),     // Use the class member client
        client: client                // Use the class member client
    );

    emailController = TextEditingController();
    otpController = TextEditingController();
    usernameController = TextEditingController();
    usernameController.addListener(() {
      usernameText.value = usernameController.text;
    });

    // Call the updated version
    // Note: onInit cannot be async directly. checkExistingSession needs to be called carefully.
    // Typically, you might not await it here or use a .then() approach if absolutely needed,
    // or ensure checkExistingSession handles its own loading state without blocking onInit.
    // For this refactor, we'll keep it as per plan, assuming GetX handles it.
    checkExistingSession();
  }

  @override
  void onClose() {
    emailController.dispose();
    otpController.dispose();
    usernameController.dispose();
    usernameText.value = '';
    cancelTimers();
    super.onClose();
  }

  Future<void> checkExistingSession() async {
    isLoading.value = true;
    try {
      final models.User? user = await _authService.getCurrentUserSession();
      if (user != null) {
        // User is authenticated
        bool hasUsername = await ensureUsername(); // ensureUsername will use _userService
        if (hasUsername) {
          if (Get.currentRoute == '/' || Get.currentRoute == '/login' || Get.currentRoute == '/set_username') { // Added /login
            await Get.offAllNamed('/home');
          }
        } else {
          if (Get.currentRoute != '/set_username') {
            await Get.offAllNamed('/set_username');
          }
        }
      } else {
        // No active session, or error that implies no session
        // Navigate to SignInPage if not already there or on splash
         if (Get.currentRoute != '/' && Get.currentRoute != '/login') { // Added /login
           Get.offAllNamed('/');
         }
      }
    } on AppwriteException catch (e) {
      logger.i('AppwriteException during session check, navigating to sign-in: $e');
      if (Get.currentRoute != '/' && Get.currentRoute != '/login') { // Added /login
           Get.offAllNamed('/');
      }
    } catch (e) {
      logger.e('Error checking session, navigating to sign-in', error: e);
       if (Get.currentRoute != '/' && Get.currentRoute != '/login') { // Added /login
           Get.offAllNamed('/');
      }
    } finally {
      isLoading.value = false;
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
      Get.snackbar(
        'invalid_email'.tr,
        'invalid_email_message'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
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
      final models.Token tokenDetails = await _authService.sendOTP(email);
      userId = tokenDetails.userId; // Assuming 'userId' is still a class member String?
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
      Get.snackbar(
        'invalid_otp'.tr,
        'invalid_otp_message'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isLoading.value = true;
    try {
      // The AuthService.verifyOTP should create the session.
      await _authService.verifyOTP(userId!, otp); // otp is local var, userId is class member

      bool hasUsername = await ensureUsername(); // ensureUsername will use _userService
      if (hasUsername) {
        await Get.offAllNamed('/home');
      } else {
        await Get.offAllNamed('/set_username');
      }
      // Clear only OTP specific fields after successful verification
      otpController.clear();
      // isOTPSent.value = false; // This was already present below, remove duplication
      // Timers would have run their course or been cancelled by going back.
      // No need to call the old clearControllers() or the new comprehensive reset.
      isOTPSent.value = false;

    } on AppwriteException catch (e) {
      logger.e('AppwriteException in verifyOTP', error: e);
      String errorMessage = 'failed_to_verify_otp'.tr;

        if (e.code == 400) {
          errorMessage = 'invalid_otp_message'.tr;
        } else if (e.code == 401) {
          errorMessage = 'unauthorized'.tr;
        } else if (e.code == 500) {
          errorMessage = 'server_error'.tr;
        }

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
    resendCooldown.value = AppConstants.resendCooldownDuration;
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
    otpExpiration.value = AppConstants.otpExpirationDuration;
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
    otpController.clear();
    isOTPSent.value = false; // Go back to email input UI
    cancelTimers(); // Stop OTP timers
    canResendOTP.value = true; // Allow immediate resend if they go back
    resendCooldown.value = AppConstants.resendCooldownDuration; // Reset cooldown display
    // Do NOT clear emailController.text here
  }

  void cancelTimers() {
    _resendTimer?.cancel();
    _otpTimer?.cancel();
    _usernameDebounce?.cancel(); // Also cancel username debounce if active
  }

  // Removed old clearControllers() method.
  // void clearControllers() { ... }

  void resetAllAuthRelatedStateAndForms() {
      emailController.clear();
      otpController.clear();
      // usernameController is handled by clearUsernameInput()
      clearUsernameInput();

      // Reset reactive state related to auth
      // usernameText.value is cleared by clearUsernameInput's effect on usernameController listener
      username.value = '';     // The actual username from profile
      profilePictureUrl.value = '';
      isOTPSent.value = false;

      // Reset OTP process specific state
      userId = null; // The temporary Appwrite User ID from createEmailToken
      canResendOTP.value = true;
      resendCooldown.value = AppConstants.resendCooldownDuration; // Reset to initial
      otpExpiration.value = AppConstants.otpExpirationDuration; // Reset to initial

      cancelTimers(); // Cancel any running timers (OTP, debounce etc.)
  }

  Future<bool> ensureUsername() async {
    final prefs = await SharedPreferences.getInstance();
    // final dbId = dotenv.env[_databaseIdKey] ?? 'StarChat_DB'; // Managed by UserService
    // final collectionId = dotenv.env[_profilesCollectionKey] ?? 'user_profiles'; // Managed by UserService

    try {
      final currentUser = await _authService.getCurrentUserSession();
      if (currentUser == null) {
          // No user session, cannot ensure username.
          // This case should ideally be handled by checkExistingSession routing to login.
          // If somehow called without a session, clear local username and return false.
          await prefs.remove('username');
          username.value = '';
          profilePictureUrl.value = '';
          return false;
      }
      final uid = currentUser.$id;

      final models.Document? profile = await _userService.getUserProfile(uid);
      if (profile != null && profile.data[AppConstants.usernameField] != null && profile.data[AppConstants.usernameField].isNotEmpty) { // check for empty string
        username.value = profile.data[AppConstants.usernameField];
        if (profile.data[AppConstants.profilePictureField] != null && profile.data[AppConstants.profilePictureField].isNotEmpty) { // check for empty string
          profilePictureUrl.value = profile.data[AppConstants.profilePictureField];
        }
        await prefs.setString(AppConstants.usernameField, username.value); // Use AppConstants for prefs key if desired
        return true;
      }

      // If no username found on server, clear any cached value
      await prefs.remove(AppConstants.usernameField); // Use AppConstants for prefs key
      username.value = '';
      profilePictureUrl.value = '';
      return false;
    } catch (e) {
      logger.e('Error fetching username from server', error: e);

      // Fallback to cached username only when the server cannot be reached
      final cachedName = prefs.getString(AppConstants.usernameField); // Use AppConstants for prefs key
      if (cachedName != null && cachedName.isNotEmpty) { // check for empty string
        username.value = cachedName;
        // Assuming profile picture URL might also be cached or not critical for fallback
        return true;
      }

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
                            // Corrected: dbId and collectionId are not needed for _saveUsername
                            await _saveUsername(uid, textController.text, prefs);
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
    // final dbId = dotenv.env[_databaseIdKey] ?? 'StarChat_DB'; // Managed by UserService
    // final collectionId = dotenv.env[_profilesCollectionKey] ?? 'user_profiles'; // Managed by UserService
    try {
      usernameAvailable.value = await _userService.checkUsernameAvailability(name);
      return usernameAvailable.value;
    } on AppwriteException catch (e) {
      logger.e('AppwriteException checking username', error: e);
      final message = e.message ?? 'username_check_error'.tr;
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
      return false;
    } finally {
      isCheckingUsername.value = false;
      hasCheckedUsername.value = true;
    }
  }

  Future<void> _saveUsername(String uid, String name, SharedPreferences prefs) async {
    try {
      final models.Document? existingProfile = await _userService.getUserProfile(uid);
      await _userService.saveUserProfile(
        documentId: existingProfile?.$id,
        userId: uid,
        username: name,
      );
      username.value = name;
      await prefs.setString('username', name);
    } catch (e) {
      logger.e('Error saving username', error: e);
      // Optionally, rethrow or show a snackbar
    }
  }

  void onUsernameChanged(String value) {
    usernameText.value = value;
    isUsernameValid.value = isValidUsername(value);
    _usernameDebounce?.cancel();
    hasCheckedUsername.value = false;
    if (!isUsernameValid.value) {
      usernameAvailable.value = false;
      isCheckingUsername.value = false;
      return;
    }
    isCheckingUsername.value = true;
    _usernameDebounce = Timer(AppConstants.usernameDebounceDuration, () {
      _checkUsernameAvailability(value);
    });
  }

  void clearUsernameInput() {
    usernameController.clear();
    isUsernameValid.value = false;
    usernameAvailable.value = false;
    usernameText.value = '';
    isCheckingUsername.value = false;
    _usernameDebounce?.cancel();
  }

  Future<void> checkUsernameAvailability() async {
    final name = usernameController.text.trim();
    if (name.isEmpty) {
      Get.snackbar(
        'error'.tr,
        'empty_username'.tr,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 10),
      );
      return;
    }
    if (!isValidUsername(name)) {
      Get.snackbar(
        'error'.tr,
        'invalid_username_message'.tr,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 10),
      );
      return;
    }
    hasCheckedUsername.value = false;
    await _checkUsernameAvailability(name);
  }

  Future<String?> fetchCurrentUserId() async {
    try {
      final models.User? user = await _authService.getCurrentUserSession();
      return user?.$id;
    } catch (e) {
      logger.e('Error fetching user ID', error: e);
      return null;
    }
  }
  Future<void> submitUsername() async {
    final name = usernameController.text.trim();
    if (!isValidUsername(name)) {
      Get.snackbar(
        'error'.tr,
        'invalid_username_message'.tr,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 10),
      );
      return;
    }
    isLoading.value = true;

    final available = await _userService.checkUsernameAvailability(name); // Uses service
    if (!available) {
      Get.snackbar(
        'error'.tr,
        'username_taken'.tr,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 10),
      );
      isLoading.value = false;
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final currentUser = await _authService.getCurrentUserSession();
    if (currentUser == null) {
        Get.snackbar('Error', 'No active session. Please sign in again.'); // Not translated, for brevity
        isLoading.value = false;
        Get.offAllNamed('/');
        return;
    }
    final uid = currentUser.$id;

    // _saveUsername was simplified and might be directly used or its logic incorporated here
    try {
      await _saveUsername(uid, name, prefs); // Call the updated _saveUsername
      // username.value and prefs.setString are handled by _saveUsername which should also use AppConstants for prefs keys

      isLoading.value = false;
      if (Get.previousRoute.isEmpty) {
        Get.offAllNamed('/home');
      } else {
        Get.back();
      }
    } catch (e) {
      logger.e('Error submitting username', error: e);
      Get.snackbar('Error', 'Failed to save username. Please try again.'); // Not translated
      isLoading.value = false;
    }
    // Removed misplaced else { Get.back(); } block from here
  }

  // Renamed deleteUsername to clearUserUsernameEntry
  Future<void> clearUserUsernameEntry() async {
    isLoading.value = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUser = await _authService.getCurrentUserSession();
      if (currentUser == null) {
        Get.snackbar('Error', 'No active session.'); // Not translated
        isLoading.value = false;
        return;
      }
      final uid = currentUser.$id;

      await _userService.setUsernameEmpty(uid); // Calls the service method

      username.value = ""; // Clear local state
      await prefs.remove(AppConstants.usernameField); // Clear cache using AppConstants key

      // ensureUsername might try to re-fetch or show set_username page again.
      // This behavior needs to be clear. If user clears username, where should they go?
      // For now, keep ensureUsername to re-evaluate state.
      await ensureUsername();

      Get.snackbar('success'.tr, 'username_cleared'.tr, // Or a more accurate translation key
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) { // Catch generic Exception as services might throw AppwriteException or others
      logger.e('Error clearing username entry', error: e);
      Get.snackbar('error'.tr, 'failed_to_clear_username'.tr, // Ensure this key exists or update it
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }
  Future<void> deleteUserAccount() async {
    isLoading.value = true;
    try {
      await _authService.requestAccountDeletion();
      logger.i('Account deletion request processed.'); // Updated log message
      // clearControllers(); // Replaced by resetAllAuthRelatedStateAndForms
      resetAllAuthRelatedStateAndForms();
      // isOTPSent.value = false; // Handled by resetAllAuthRelatedStateAndForms
      // Navigation and snackbar might change depending on how requestAccountDeletion is handled (e.g., if it throws UnimplementedError)
      Get.offAllNamed('/');
      Get.snackbar(
        'success'.tr, // This might be optimistic if it's just a request
        'account_deletion_requested'.tr, // Needs new translation key
        snackPosition: SnackPosition.BOTTOM,
      );
    } on AppwriteException catch (e) { // Catch AppwriteException specifically if services throw them
      logger.e('Error requesting account deletion', error: e);
      Get.snackbar(
        'error'.tr,
        'failed_to_request_account_deletion'.tr, // Needs new translation key
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) { // Catch other errors, like UnimplementedError
      logger.e('Error during account deletion process', error: e);
      Get.snackbar(
        'error'.tr,
        e is UnimplementedError ? 'Feature not implemented' : 'unexpected_error'.tr, // Handle UnimplementedError gracefully
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    try {
      await _authService.logout();
    } catch (e) {
      logger.e('Error during logout', error: e); // Changed log message slightly
    } finally {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(AppConstants.usernameField); // Use AppConstants for prefs key
      } catch (e) {
        logger.e('Error clearing cached username', error: e);
      }
      // clearControllers(); // Replaced by resetAllAuthRelatedStateAndForms
      resetAllAuthRelatedStateAndForms();
      // isOTPSent.value = false; // Handled by resetAllAuthRelatedStateAndForms
      // username.value = ''; // Handled by resetAllAuthRelatedStateAndForms
      // profilePictureUrl.value = ''; // Handled by resetAllAuthRelatedStateAndForms
      Get.offAllNamed('/');
    }
  }

  Future<void> updateProfilePicture(File file) async {
    isLoading.value = true;
    // final bucketId = dotenv.env[_bucketIdKey] ?? 'profile_pics'; // Managed by UserService
    // final dbId = dotenv.env[_databaseIdKey] ?? 'StarChat_DB'; // Managed by UserService
    // final collectionId = dotenv.env[_profilesCollectionKey] ?? 'user_profiles'; // Managed by UserService
    try {
      final currentUser = await _authService.getCurrentUserSession();
      if (currentUser == null) {
        Get.snackbar('Error', 'No active session.'); // Not translated
        isLoading.value = false;
        return;
      }
      final uid = currentUser.$id;

      final String newUrl = await _userService.uploadProfilePictureAndUpdateUser(uid, file);
      profilePictureUrl.value = newUrl;
      Get.snackbar('Success', 'Profile picture updated!'); // Not translated

    } catch (e) {
      logger.e('Error updating profile picture', error: e);
      Get.snackbar('error'.tr, 'failed_to_update_profile_picture'.tr, // Needs new translation key
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }
}
