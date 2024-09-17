import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:appwrite/appwrite.dart';
import 'package:logger/logger.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // To load environment variables

class AuthController extends GetxController {
  final Client client = Client();
  late Account account;
  late Functions functions;

  final isLoading = false.obs;
  final isOTPSent = false.obs;

  final emailController = TextEditingController();
  final otpController = TextEditingController();

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

  @override
  void onInit() {
    super.onInit();
    // Initialize client using .env variables
    client
      .setEndpoint(dotenv.env['APPWRITE_ENDPOINT']!) // Load endpoint from .env
      .setProject(dotenv.env['APPWRITE_PROJECT_ID']!); // Load project ID from .env
    account = Account(client);
    functions = Functions(client);

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

      canResendOTP.value = false;
      startResendCooldownTimer();
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

      Get.snackbar('error'.tr, errorMessage, snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      logger.e('Unknown error in sendOTP', error: e);
      Get.snackbar('error'.tr, 'unexpected_error'.tr, snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resendOTP() async {
    // Resend OTP logic: Simply call the sendOTP method again
    await sendOTP();
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
        await account.createSession(
          userId: userId!,
          secret: otp,
        );

        // Call the Appwrite function to store user information after OTP verification
        await executeCloudFunction(emailController.text.trim(), userId!);

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

        Get.snackbar('error'.tr, errorMessage, snackPosition: SnackPosition.BOTTOM);
      } catch (e) {
        logger.e('Unknown error in verifyOTP', error: e);
        Get.snackbar('error'.tr, 'unexpected_error'.tr, snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      logger.e('Error in verifyOTP', error: e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> executeCloudFunction(String email, String userId) async {
    try {
      final result = await functions.createExecution(
        functionId: dotenv.env['APPWRITE_FUNCTION_ID_storeUserData']!, // Use function ID from .env
        body: jsonEncode({'email': email, 'userId': userId}),
      );
      logger.i('Function executed successfully: ${result.responseBody}');
    } catch (e) {
      logger.e('Error executing function: $e');
    }
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
    emailController.clear();
    otpController.clear();
    cancelTimers();
  }

  Future<void> deleteUserAccount() async {
    isLoading.value = true;
    try {
      await account.deleteIdentity(identityId: userId!);
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
      Get.snackbar('error'.tr, 'failed_to_delete_account'.tr, snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      logger.e('Unknown error deleting account', error: e);
      Get.snackbar('error'.tr, 'unexpected_error'.tr, snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }
}
