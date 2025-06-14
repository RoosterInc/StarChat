import 'package:get/get.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../controllers/auth_controller.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../features/social_feed/services/feed_service.dart';
import '../features/social_feed/controllers/feed_controller.dart';
import '../features/social_feed/controllers/comments_controller.dart';
import '../features/bookmarks/controllers/bookmark_controller.dart';
import 'package:appwrite/appwrite.dart' as appwrite;
import '../features/notifications/services/mention_service.dart';
import '../features/notifications/services/notification_service.dart';

class FeedBinding extends Bindings {
  @override
  void dependencies() {
    final auth = Get.find<AuthController>();

    if (!Get.isRegistered<FeedController>()) {
      final service = FeedService(
        databases: auth.databases,
        storage: auth.storage,
        functions: appwrite.Functions(auth.client),
        databaseId: dotenv.env['APPWRITE_DATABASE_ID'] ?? 'StarChat_DB',
        postsCollectionId:
            dotenv.env['FEED_POSTS_COLLECTION_ID'] ?? 'feed_posts',
        commentsCollectionId:
            dotenv.env['POST_COMMENTS_COLLECTION_ID'] ?? 'post_comments',
        likesCollectionId:
            dotenv.env['POST_LIKES_COLLECTION_ID'] ?? 'post_likes',
        repostsCollectionId:
            dotenv.env['POST_REPOSTS_COLLECTION_ID'] ?? 'post_reposts',
        bookmarksCollectionId:
            dotenv.env['BOOKMARKS_COLLECTION_ID'] ?? 'bookmarks',
        connectivity: Get.put(Connectivity()),
        linkMetadataFunctionId:
            dotenv.env['FETCH_LINK_METADATA_FUNCTION_ID'] ?? 'fetch_link_metadata',
      );
      Get.put<FeedController>(FeedController(service: service));
      Get.put<BookmarkController>(BookmarkController(service: service));
    }

    if (Get.isRegistered<NotificationService>() &&
        !Get.isRegistered<MentionService>()) {
      final notification = Get.find<NotificationService>();
      Get.lazyPut<MentionService>(() => MentionService(
            databases: auth.databases,
            notificationService: notification,
            databaseId: dotenv.env['APPWRITE_DATABASE_ID'] ?? 'StarChat_DB',
            profilesCollectionId:
                dotenv.env['USER_PROFILES_COLLECTION_ID'] ?? 'user_profiles',
          ));
    }

    if (!Get.isRegistered<CommentsController>()) {
      final service = Get.find<FeedController>().service;
      Get.put<CommentsController>(CommentsController(service: service));
    }
  }
}
