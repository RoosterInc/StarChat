import 'dart:async';
import 'dart:convert';
import 'package:appwrite/models.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:appwrite/appwrite.dart';
import 'package:logger/logger.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthController extends GetxController {
  final Client client = Client();
  late Account account;
  late Functions functions;

  final isLoading = false.obs;
  final isOTPSent = false.obs;
  final isAuthenticated = false.obs;
  final isInitializing = true.obs;

  // Observable strings that sync with controllers
  final emailText = ''.obs;
  final otpText = ''.obs;

  // Controllers - never dispose except in onClose
  final emailController = TextEditingController();
  final otpController = TextEditingController();

  String? userId;
  User? currentUser;

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
  
  // SharedPreferences key for storing email
  static const String _lastEmailKey = 'last_user_email';

  @override
  void onInit() {
    super.onInit();
    
    // Initialize client using .env variables
    client
      .setEndpoint(dotenv.env['APPWRITE_ENDPOINT']!) // Load endpoint from .env
      .setProject(dotenv.env['APPWRITE_PROJECT_ID']!); // Load project ID from .env
    account = Account(client);
    functions = Functions(client);

    // Set up listeners for text controllers to sync with observable strings
    emailController.addListener(() {
      emailText.value = emailController.text;
    });
    
    otpController.addListener(() {
      otpText.value = otpController.text;
    });

    // Load saved email when controller initializes
    _loadSavedEmail();
  }

  @override
  void onClose() {
    // Only dispose controllers when the controller itself is destroyed
    emailController.dispose();
    otpController.dispose();
    cancelTimers();
    super.onClose();
  }

  Future<void> _loadSavedEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString(_lastEmailKey);
      if (savedEmail != null && savedEmail.isNotEmpty) {
        emailController.text = savedEmail;
        emailText.value = savedEmail;
        logger.i('Loaded saved email: $savedEmail');
      }
    } catch (e) {
      logger.e('Error loading saved email', error: e);
    }
  }

  Future<void> _saveEmail(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastEmailKey, email);
      logger.i('Email saved successfully');
    } catch (e) {
      logger.e('Error saving email', error: e);
    }
  }

  Future<void> _clearSavedEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastEmailKey);
      logger.i('Saved email cleared');
    } catch (e) {
      logger.e('Error clearing saved email', error: e);
    }
  }

  Future<void> checkExistingSession() async {
    try {
      isInitializing.value = true;
      final user = await account.get();
      currentUser = user;
      isAuthenticated.value = true;
      logger.i('Active session found for user: ${user.email}');
      
      // Navigate to home page
      await Future.delayed(const Duration(milliseconds: 500));
      Get.offAllNamed('/home');
    } on AppwriteException catch (e) {
      logger.i('No active session: ${e.code} - ${e.message}');
      isAuthenticated.value = false;
      currentUser = null;
      
      // Navigate to sign-in page
      await Future.delayed(const Duration(milliseconds: 500));
      Get.offAllNamed('/');
    } catch (e) {
      logger.e('Error checking session', error: e);
      isAuthenticated.value = false;
      currentUser = null;
      
      // Navigate to sign-in page on error
      await Future.delayed(const Duration(milliseconds: 500));
      Get.offAllNamed('/');
    } finally {
      isInitializing.value = false;
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
    logger.i('Starting sendOTP process for email: $email');

    if (!isValidEmail(email)) {
      logger.w('Invalid email format: $email');
      Get.snackbar(
        'invalid_email'.tr,
        'invalid_email_message'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (!canResendOTP.value) {
      logger.w('Cannot resend OTP yet. Cooldown: ${resendCooldown.value}s');
      Get.snackbar(
        'wait'.tr,
        'resend_otp_in'.trParams({'seconds': resendCooldown.value.toString()}),
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      logger.w('No internet connection');
      Get.snackbar(
        'no_internet'.tr,
        'check_internet'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isLoading.value = true;
    logger.i('Setting loading to true, calling Appwrite...');
    
    try {
      final result = await account.createEmailToken(
        userId: ID.unique(),
        email: email,
      );

      userId = result.userId;
      logger.i('OTP creation successful. UserId: $userId');
      
      // CRITICAL: Set OTP sent flag BEFORE other operations
      isOTPSent.value = true;
      logger.i('Set isOTPSent to true');

      // Save email for future use
      await _saveEmail(email);

      Get.snackbar(
        'success'.tr,
        'otp_sent'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );

      canResendOTP.value = false;
      startResendCooldownTimer();
      startOTPExpirationTimer();
      
      logger.i('OTP process completed successfully. isOTPSent: ${isOTPSent.value}');
      
    } on AppwriteException catch (e) {
      logger.e('AppwriteException in sendOTP: ${e.code} - ${e.message}');
      String errorMessage = _getOTPErrorMessage(e);
      Get.snackbar('error'.tr, errorMessage, snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      logger.e('Unknown error in sendOTP', error: e);
      Get.snackbar('error'.tr, 'unexpected_error'.tr, snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
      logger.i('Set loading to false. Final isOTPSent state: ${isOTPSent.value}');
    }
  }

  Future<void> resendOTP() async {
    logger.i('Resending OTP...');
    await sendOTP();
  }

  Future<void> verifyOTP() async {
    String otp = otpController.text.trim();
    logger.i('Starting OTP verification for: $otp');

    if (!isValidOTP(otp)) {
      logger.w('Invalid OTP format: $otp');
      Get.snackbar(
        'invalid_otp'.tr,
        'invalid_otp_message'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isLoading.value = true;
    try {
      // Check if there's already an active session
      try {
        final user = await account.get();
        currentUser = user;
        isAuthenticated.value = true;
        logger.i('Active session found, navigating to home');
        Get.offAllNamed('/home');
        return;
      } on AppwriteException catch (e) {
        logger.i('No existing session (${e.code}), proceeding with OTP verification');
      }

      // Verify OTP and create new session
      await account.createSession(
        userId: userId!,
        secret: otp,
      );

      logger.i('OTP verified successfully, session created');

      // Get user information after session creation
      final user = await account.get();
      currentUser = user;
      isAuthenticated.value = true;

      // Call the Appwrite function to store user information
      await executeCloudFunction(emailController.text.trim(), userId!);

      // Clear OTP-related state
      cancelTimers();
      otpController.clear();
      otpText.value = '';
      isOTPSent.value = false;

      Get.offAllNamed('/home');
      
    } on AppwriteException catch (e) {
      logger.e('AppwriteException in verifyOTP: ${e.code} - ${e.message}');
      String errorMessage = _getVerifyErrorMessage(e);
      Get.snackbar('error'.tr, errorMessage, snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      logger.e('Unknown error in verifyOTP', error: e);
      Get.snackbar('error'.tr, 'unexpected_error'.tr, snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> executeCloudFunction(String email, String userId) async {
    try {
      final result = await functions.createExecution(
        functionId: dotenv.env['APPWRITE_FUNCTION_ID_storeUserData']!,
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
    logger.i('Going back to email input');
    cancelTimers();
    otpController.clear();
    otpText.value = '';
    isOTPSent.value = false;
    canResendOTP.value = true;
  }

  void cancelTimers() {
    _resendTimer?.cancel();
    _otpTimer?.cancel();
  }

  void clearEmailText() {
    emailController.clear();
    emailText.value = '';
  }

  void clearOTPText() {
    otpController.clear();
    otpText.value = '';
  }

  Future<void> logout() async {
    try {
      isLoading.value = true;
      logger.i('Starting logout process');
      
      // Delete current session
      await account.deleteSession(sessionId: 'current');
      
      // Clear local state but keep saved email
      currentUser = null;
      isAuthenticated.value = false;
      clearOTPText(); // Only clear OTP, keep email
      cancelTimers();
      isOTPSent.value = false;
      userId = null;
      
      logger.i('User logged out successfully');
      Get.offAllNamed('/');
      
    } on AppwriteException catch (e) {
      logger.e('Error during logout: ${e.code} - ${e.message}');
      // Even if logout fails on server, clear local state
      currentUser = null;
      isAuthenticated.value = false;
      clearOTPText();
      cancelTimers();
      isOTPSent.value = false;
      Get.offAllNamed('/');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> clearAllData() async {
    try {
      logger.i('Clearing all user data');
      await _clearSavedEmail();
      clearEmailText();
      clearOTPText();
      isOTPSent.value = false;
      userId = null;
      currentUser = null;
      isAuthenticated.value = false;
      cancelTimers();
      logger.i('All user data cleared successfully');
    } catch (e) {
      logger.e('Error clearing all data', error: e);
    }
  }

  // Session validation middleware
  Future<bool> validateSession() async {
    try {
      final user = await account.get();
      currentUser = user;
      isAuthenticated.value = true;
      return true;
    } on AppwriteException catch (e) {
      logger.w('Session validation failed: ${e.code}');
      isAuthenticated.value = false;
      currentUser = null;
      return false;
    }
  }

  // Auto session refresh (call this periodically if needed)
  Future<void> refreshSession() async {
    if (isAuthenticated.value) {
      final isValid = await validateSession();
      if (!isValid) {
        logger.w('Session expired, redirecting to login');
        Get.offAllNamed('/');
      }
    }
  }

  String _getOTPErrorMessage(AppwriteException e) {
    switch (e.code) {
      case 400:
        return 'invalid_email_message'.tr;
      case 429:
        return 'too_many_requests'.tr;
      case 500:
        return 'server_error'.tr;
      default:
        return 'failed_to_send_otp'.tr;
    }
  }

  String _getVerifyErrorMessage(AppwriteException e) {
    switch (e.code) {
      case 400:
        return 'invalid_otp_message'.tr;
      case 401:
        return 'unauthorized'.tr;
      case 500:
        return 'server_error'.tr;
      default:
        return 'failed_to_verify_otp'.tr;
    }
  }
}