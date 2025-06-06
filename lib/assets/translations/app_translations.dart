import 'package:get/get.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'en_US': {
          'email_sign_in': 'Email OTP Sign-In',
          'enter_email': 'Enter your email to receive an OTP for sign-in.',
          'email': 'Email',
          'send_otp': 'Send OTP',
          'enter_otp': 'Enter the OTP sent to your email.',
          'otp_expires_in': 'OTP expires in @seconds seconds.',
          'otp': 'OTP',
          'verify_otp': 'Verify OTP',
          'resend_otp': 'Resend OTP',
          'resend_otp_in': 'Resend OTP in @seconds seconds',
          'success': 'Success',
          'error': 'Error',
          'otp_sent': 'OTP sent to your email',
          'failed_to_send_otp': 'Failed to send OTP',
          'failed_to_verify_otp': 'Failed to verify OTP',
          'invalid_email': 'Invalid Email',
          'invalid_email_message': 'Please enter a valid email address.',
          'invalid_otp': 'Invalid OTP',
          'invalid_otp_message': 'Please enter a valid 6-digit OTP.',
          'wait': 'Wait',
          'no_internet': 'No Internet',
          'check_internet': 'Please check your internet connection.',
          'otp_expired': 'OTP Expired',
          'otp_expired_message': 'Your OTP has expired. Please request a new one.',
          'logout': 'Logout',
          'home_page': 'Home Page',
          'signed_in': 'You are now signed in!',
          'delete_account': 'Delete Account',
          'delete_account_confirmation': 'Are you sure you want to delete your account?',
          'cancel': 'Cancel',
          'delete': 'Delete',
          'account_deleted': 'Your account has been deleted.',
          'failed_to_delete_account': 'Failed to delete account.',
          'too_many_requests': 'Too many requests. Please try again later.',
          'server_error': 'Server error. Please try again later.',
          'unexpected_error': 'An unexpected error occurred.',
          'unauthorized': 'Unauthorized. Please request a new OTP.',
        },
        'es_ES': {
          // Add the Spanish translations here...
        },
      };
}