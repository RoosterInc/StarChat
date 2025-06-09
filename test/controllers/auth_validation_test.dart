import 'package:flutter_test/flutter_test.dart';

import 'package:myapp/controllers/auth_controller.dart';

void main() {
  group('AuthController validations', () {
    final controller = AuthController();

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
