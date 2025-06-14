import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/features/social_feed/screens/post_detail_page.dart';
import 'package:myapp/features/social_feed/screens/comment_thread_page.dart';

void main() {
  test('sanitizeCommentForTest unescapes HTML entities', () {
    const input = 'Tom &amp; Jerry';
    expect(sanitizeCommentForTest(input), 'Tom & Jerry');
  });

  test('sanitizeCommentThreadForTest unescapes HTML entities', () {
    const input = 'Tom &amp; Jerry';
    expect(sanitizeCommentThreadForTest(input), 'Tom & Jerry');
  });
}
