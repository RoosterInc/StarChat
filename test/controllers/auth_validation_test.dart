import 'package:flutter_test/flutter_test.dart';
import 'package:email_validator/email_validator.dart';

class FakeAuthController {
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
}

void main() {
  group('AuthController validations', () {
    final controller = FakeAuthController();

    test('validates email format', () {
      expect(controller.isValidEmail('test@example.com'), isTrue);
      expect(controller.isValidEmail('invalid'), isFalse);
    });

    test('validates OTP format', () {
      expect(controller.isValidOTP('123456'), isTrue);
      expect(controller.isValidOTP('abc123'), isFalse);
    });

    test('validates username format', () {
      expect(controller.isValidUsername('user_1'), isTrue);
      expect(controller.isValidUsername('x'), isFalse);
    });
  });
}
