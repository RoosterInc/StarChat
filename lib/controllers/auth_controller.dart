import 'dart:async';
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
  final Client serverClient = Client();
  late Account account;
  late Databases databases;
  late Databases serverDatabases;

  final isLoading = false.obs;
  final isOTPSent = false.obs;
  final isCheckingUsername = false.obs;
  final usernameAvailable = false.obs;
  final username = ''.obs;

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
  static const String _apiKeyKey = 'APPWRITE_API_KEY';

  @override
  void onInit() {
    super.onInit();
    final endpoint = dotenv.env[_endpointKey] ?? '';
    final projectId = dotenv.env[_projectIdKey] ?? '';
    client.setEndpoint(endpoint).setProject(projectId);

    final apiKey = dotenv.env[_apiKeyKey];
    if (apiKey != null && apiKey.isNotEmpty) {
      serverClient
          .setEndpoint(endpoint)
          .setProject(projectId)
          .setKey(apiKey);
      serverDatabases = Databases(serverClient);
    } else {
      serverDatabases = Databases(client);
    }

    emailController = TextEditingController();
    otpController = TextEditingController();

    account = Account(client);
    databases = Databases(client);

    checkExistingSession();
  }

  @override
  void onClose() {
    emailController.dispose();
    otpController.dispose();
    cancelTimers();
    super.onClose();
  }

  Future<void> checkExistingSession() async {
    try {
      isLoading.value = true;
      await account.get();
      await ensureUsername();
      Get.offAllNamed('/home');
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
      Get.offAllNamed('/home');
    } on AppwriteException {
      logger.i('No existing session, verifying OTP...');
      try {
        await account.updateMagicURLSession(
          userId: userId!,
          secret: otp,
        );

        await ensureUsername();
        Get.offAllNamed('/home');
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
    emailController = TextEditingController();
    otpController = TextEditingController();
    cancelTimers();
  }

  Future<void> ensureUsername() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString('username') != null) {
      username.value = prefs.getString('username')!;
      return;
    }

    final dbId = dotenv.env[_databaseIdKey] ?? 'StarChat_DB';
    final collectionId = dotenv.env[_profilesCollectionKey] ?? 'user_profiles';
    final session = await account.get();
    final uid = session.$id;

    try {
      final result = await serverDatabases.listDocuments(
        databaseId: dbId,
        collectionId: collectionId,
        queries: [Query.equal('userId', uid)],
      );
      if (result.documents.isNotEmpty) {
        final data = result.documents.first.data;
        if (data['username'] != null && data['username'] != '') {
          username.value = data['username'];
          await prefs.setString('username', username.value);
          return;
        }
      }
    } catch (e) {
      logger.e('Error fetching username', error: e);
    }

    await _promptForUsername(dbId, collectionId, uid, prefs);
  }

  Future<void> _promptForUsername(
      String dbId, String collectionId, String uid, SharedPreferences prefs) async {
    final controller = TextEditingController();
    usernameAvailable.value = false;

    await Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('enter_username'.tr),
            content: Obx(() => TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: 'username'.tr,
                    suffixIcon: isCheckingUsername.value
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            usernameAvailable.value ? Icons.check : Icons.close,
                            color: usernameAvailable.value
                                ? Colors.green
                                : Colors.red,
                          ),
                  ),
                  onChanged: (value) async {
                    setState(() {});
                    await _checkUsernameAvailability(value);
                  },
                )),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: Text('cancel'.tr),
              ),
              Obx(() => ElevatedButton(
                    onPressed: usernameAvailable.value
                        ? () async {
                            await _saveUsername(
                                dbId, collectionId, uid, controller.text, prefs);
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

  Future<void> _checkUsernameAvailability(String name) async {
    if (name.isEmpty) {
      usernameAvailable.value = false;
      return;
    }
    isCheckingUsername.value = true;
    final dbId = dotenv.env[_databaseIdKey] ?? 'StarChat_DB';
    final collectionId = dotenv.env[_profilesCollectionKey] ?? 'user_profiles';
    try {
      final result = await serverDatabases.listDocuments(
        databaseId: dbId,
        collectionId: collectionId,
        queries: [Query.equal('username', name)],
      );
      usernameAvailable.value = result.documents.isEmpty;
    } catch (e) {
      usernameAvailable.value = false;
    } finally {
      isCheckingUsername.value = false;
    }
  }

  Future<void> _saveUsername(String dbId, String collectionId, String uid,
      String name, SharedPreferences prefs) async {
    try {
      await serverDatabases.createDocument(
        databaseId: dbId,
        collectionId: collectionId,
        documentId: ID.unique(),
        data: {
          'userId': uid,
          'username': name,
          'firstName': '',
          'lastName': '',
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );
      username.value = name;
      await prefs.setString('username', name);
    } catch (e) {
      logger.e('Error saving username', error: e);
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
}