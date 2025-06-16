import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/features/social_feed/widgets/reaction_bar.dart';

void main() {
  testWidgets('ReactionBar wraps in small width without overflow', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          width: 150,
          child: ReactionBar(
            onLike: null,
            onComment: null,
            onRepost: null,
          onBookmark: null,
          onShare: null,
          likeCount: 1,
          commentCount: 1,
          repostCount: 1,
          shareCount: 1,
          bookmarkCount: 1,
        ),
      ),
    ),
  );
    await tester.pump();
    expect(find.byType(Wrap), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
