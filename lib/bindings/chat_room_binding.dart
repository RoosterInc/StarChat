import 'package:get/get.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'auth_binding.dart';
import '../controllers/auth_controller.dart';
import '../features/social_feed/services/feed_service.dart';
import '../features/social_feed/services/poll_service.dart';
import '../features/social_feed/controllers/feed_controller.dart';
import '../features/social_feed/controllers/comments_controller.dart';
import '../features/social_feed/controllers/poll_controller.dart';

class ChatRoomBinding extends AuthBinding {
  @override
  void dependencies() {
    super.dependencies();
    final auth = Get.find<AuthController>();
    final databases = auth.databases;
    final dbId = dotenv.env['APPWRITE_DATABASE_ID'] ?? 'StarChat_DB';

    Get.lazyPut<FeedService>(() => FeedService(
          databases: databases,
          databaseId: dbId,
          postsCollectionId:
              dotenv.env['FEED_POSTS_COLLECTION_ID'] ?? 'feed_posts',
          commentsCollectionId:
              dotenv.env['POST_COMMENTS_COLLECTION_ID'] ?? 'post_comments',
        ));

    Get.lazyPut<PollService>(() => PollService(
          databases: databases,
          databaseId: dbId,
          pollsCollectionId: dotenv.env['POLLS_COLLECTION_ID'] ?? 'polls',
          votesCollectionId:
              dotenv.env['POLL_VOTES_COLLECTION_ID'] ?? 'poll_votes',
        ));

    Get.lazyPut<FeedController>(
        () => FeedController(service: Get.find<FeedService>()));
    Get.lazyPut<CommentsController>(
        () => CommentsController(service: Get.find<FeedService>()));
    Get.lazyPut<PollController>(
        () => PollController(service: Get.find<PollService>()));
  }
}
