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

class AuthController extends GetxController {
  final Client client = Client();
  late Account account;
  late Databases databases;
  late Storage storage;

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
    emailController.dispose();
    otpController.dispose();
    usernameController.dispose();
    usernameText.value = '';
    cancelTimers();
    super.onClose();
  }

  Future<void> checkExistingSession() async {
    try {
      isLoading.value = true;
      await account.get();
      bool hasUsername = await ensureUsername();
      if (hasUsername) {
        // Only redirect to home when coming from unauthenticated routes
        if (Get.currentRoute == '/' || Get.currentRoute == '/set_username') {
          await Get.offAllNamed('/home');
        }
      } else {
        if (Get.currentRoute != '/set_username') {
          await Get.offAllNamed('/set_username');
        }
      }
    } on AppwriteException catch (e) {
      logger.i('No active session: $e');
    } catch (e) {
      logger.e('Error checking session', error: e);
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
      Get.snackbar(
        'invalid_otp'.tr,
        'invalid_otp_message'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
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
      try {
        await account.updateMagicURLSession(
          userId: userId!,
          secret: otp,
        );

        bool hasUsername = await ensureUsername();
        if (hasUsername) {
          await Get.offAllNamed('/home');
        } else {
          await Get.offAllNamed('/set_username');
        }
        clearControllers();
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
  }

  void clearControllers() {
    emailController.dispose();
    otpController.dispose();
    usernameController.dispose();
    usernameController = TextEditingController();
    usernameController.addListener(() {
      usernameText.value = usernameController.text;
    });
    emailController = TextEditingController();
    otpController = TextEditingController();
    usernameText.value = '';
    cancelTimers();
  }

  Future<bool> ensureUsername() async {
    final prefs = await SharedPreferences.getInstance();
    final dbId = dotenv.env[_databaseIdKey] ?? 'StarChat_DB';
    final collectionId = dotenv.env[_profilesCollectionKey] ?? 'user_profiles';

    try {
      final session = await account.get();
      final uid = session.$id;

      final result = await databases.listDocuments(
        databaseId: dbId,
        collectionId: collectionId,
        queries: [Query.equal('userId', uid)],
      );
      if (result.documents.isNotEmpty) {
        final data = result.documents.first.data;
        if (data['username'] != null && data['username'] != '') {
          username.value = data['username'];
          if (data['profilePicture'] != null && data['profilePicture'] != '') {
            profilePictureUrl.value = data['profilePicture'];
          }
          await prefs.setString('username', username.value);
          return true;
        }
      }

      // If no username found on server, clear any cached value
      await prefs.remove('username');
      username.value = '';
      profilePictureUrl.value = '';
      return false;
    } catch (e) {
      logger.e('Error fetching username from server', error: e);

      // Fallback to cached username only when the server cannot be reached
      final cachedName = prefs.getString('username');
      if (cachedName != null) {
        username.value = cachedName;
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

  Future<void> _saveUsername(String dbId, String collectionId, String uid,
      String name, SharedPreferences prefs) async {
    try {
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
      username.value = name;
      await prefs.setString('username', name);
    } catch (e) {
      logger.e('Error saving username', error: e);
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
      Get.snackbar(
        'error'.tr,
        'invalid_username_message'.tr,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 10),
      );
      return;
    }
    isLoading.value = true;
    final available = await _checkUsernameAvailability(name);
    if (!available) {
      isLoading.value = false;
      Get.snackbar(
        'error'.tr,
        'username_taken'.tr,
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
    Get.offAllNamed('/home');
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
        queries: [Query.equal('userId', uid)],
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
        queries: [Query.equal('userId', uid)],
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
