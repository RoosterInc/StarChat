import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:appwrite/appwrite.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:myapp/features/social_feed/controllers/comments_controller.dart';
import 'package:myapp/features/social_feed/models/feed_post.dart';
import 'package:myapp/features/social_feed/models/post_comment.dart';
import 'package:myapp/features/social_feed/screens/post_detail_page.dart';
import 'package:myapp/features/social_feed/services/feed_service.dart';
import 'package:myapp/design_system/modern_ui_system.dart';

class _DelayedService extends FeedService {
  final Completer<List<PostComment>> completer = Completer<List<PostComment>>();
  _DelayedService()
      : super(
          databases: Databases(Client()),
          storage: Storage(Client()),
          functions: Functions(Client()),
          databaseId: 'db',
          postsCollectionId: 'posts',
          commentsCollectionId: 'comments',
          likesCollectionId: 'likes',
          repostsCollectionId: 'reposts',
          bookmarksCollectionId: 'bookmarks',
          connectivity: Connectivity(),
          linkMetadataFunctionId: 'link',
        );

  @override
  Future<List<PostComment>> getComments(
    String postId, {
    int limit = 20,
    String? cursor,
  }) =>
      completer.future;
}

void main() {
  testWidgets('shows skeletons while loading', (tester) async {
    final service = _DelayedService();
    final controller = CommentsController(service: service);
    Get.put(controller);

    final post = FeedPost(
      id: 'p1',
      roomId: 'r',
      userId: 'u',
      username: 'user',
      content: 'hi',
    );

    await tester.pumpWidget(GetMaterialApp(home: PostDetailPage(post: post)));
    await tester.pump();

    expect(find.byType(SkeletonLoader), findsWidgets);

    service.completer.complete(<PostComment>[]);
  });
}
