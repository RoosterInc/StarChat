import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:appwrite/appwrite.dart';
import 'package:logger/logger.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:email_validator/email_validator.dart'; // Added for email validation

class AuthController extends GetxController {
  final Client client = Client();
  late Account account;

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

  // Constants for Appwrite configuration
  static const String appwriteEndpoint =
      'https://cloud.appwrite.io/v1'; // Your Appwrite endpoint
  static const String appwriteProjectId =
      '65f5a3e4bd0514b418a4'; // Your Appwrite project ID

  @override
  void onInit() {
    super.onInit();
    client.setEndpoint(appwriteEndpoint).setProject(appwriteProjectId);

    account = Account(client);

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
    emailController.clear();
    otpController.clear();
    cancelTimers();
  }

  Future<void> deleteUserAccount() async {
    isLoading.value = true;
    try {
      await account.delete();
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