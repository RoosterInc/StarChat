import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/features/social_feed/utils/comment_validation.dart';

void main() {
  test('valid comment passes validation', () {
    expect(isValidComment('hello'), isTrue);
  });

  test('overlong comment fails validation', () {
    final longText = 'a' * (commentMaxLength + 1);
    expect(isValidComment(longText), isFalse);
  });
}

