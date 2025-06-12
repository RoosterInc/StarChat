import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/features/social_feed/models/feed_post.dart';
import 'package:myapp/features/social_feed/widgets/post_card.dart';

void main() {
  testWidgets('renders post content', (tester) async {
    final post = FeedPost(
      id: '1',
      roomId: 'r1',
      userId: 'u1',
      username: 'user',
      content: 'hello',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: PostCard(post: post),
      ),
    );
    expect(find.text('hello'), findsOneWidget);
  }, skip: true);
}
