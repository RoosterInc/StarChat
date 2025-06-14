# Implementation Guide for StarChat Social Media features

This guide provides detailed instructions  to implement 26 social media features in the StarChat Flutter app. The app leverages GetX for state management, Hive for offline caching, and a modern UI system for enhanced user experience. The AI agent’s role is to **review the existing Appwrite backend collections** (manually created) and implement the features using the provided schema, integrating with the current project structure.

## Project Overview

- **Backend**: Appwrite, with 17 collections defined in `lib/models/all_collections_config.json`.
- docs/social_media_app_data_dictionary.csv: Maps collections to features and attributes.
- **Frontend**: Flutter, using GetX for state management, Hive for local caching, and a modern UI system (`lib/design_system/modern_ui_system.dart`).
- **Features**: 26 social media features, including posting, commenting, liking, following, in-app notifications, and more.
- **Offline Support**: Enabled via Hive for caching data (posts, notifications, profiles) and queuing actions (posts, likes, comments).
- **Notifications**: In-app notifications displayed in a dedicated tab with app icon badges for unread counts, using Appwrite’s `notifications` collection and Realtime API (no APNs/FCM required).
- **Existing Features**: Social feed (`lib/features/social_feed/`), chat rooms, and profile pages are partially implemented; the AI agent must enhance and complete these while adding new features.

## Repository Structure


**Key Notes**:

- `lib/models/all_collections_config.json`: Defines the Appwrite schema (17 collections); already created manually in Appwrite.
- `docs/social_media_app_data_dictionary.csv`: Maps collections to features and attributes.
- Existing features (e.g., social feed, chat rooms) are in `lib/features/social_feed/` and `lib/pages/`.
- New modernized UI pages (e.g., `modern_home_page.dart`) are in `lib/new_codes_to_implement/` and should be integrated.

## Instructions

1. **Review Appwrite Backend**:
   - Access `lib/models/all_collections_config.json` to understand the schema of 17 collections.
2. **Implement Features**:
   - Follow the feature guide below to implement all 26 features.
   - Reuse existing files (e.g., `feed_controller.dart`, `post_card.dart`) where applicable.
   - Integrate new modernized UI pages from `lib/new_codes_to_implement/`.
   - Use GetX for state management and Hive for caching.
   - Ensure compatibility with `modern_ui_system.dart` and `enhanced_app_theme.dart`.
3. **Production-Readiness**:
   - Follow best practices for error handling, performance, security, and accessibility.
   - Test offline scenarios using Hive caching.
   - Verify real-time updates with Appwrite’s Realtime API.
4. **Testing**:
   - Update existing tests in `test/` (e.g., `feed_controller_test.dart`, `post_card_test.dart`).
   - Add new tests for implemented features.
   - Test on iOS and Android emulators, including offline mode.
5. **Documentation**:
   - Comment critical code sections for clarity.

## Setup Requirements

1. **Dependencies**: Update `pubspec.yaml` with:

   ```yaml
   dependencies:
     flutter:
       sdk: flutter
     appwrite: ^12.0.1
     get: ^4.6.5
     hive: ^2.2.3
     hive_flutter: ^1.1.0
     image_picker: ^1.0.4
     flutter_image_compress: ^2.0.4
     cached_network_image: ^3.2.3
     share_plus: ^7.0.0
     validators: ^3.0.0
     html_unescape: ^2.0.0
     flutter_app_badge: ^0.1.0
     flutter_local_notifications: ^15.0.0
     connectivity_plus: ^4.0.2
   dev_dependencies:
     hive_generator: ^2.0.0
     build_runner: ^2.4.6
     flutter_test:
       sdk: flutter
   ```

2. **Hive Initialization**: Initialize Hive in `lib/main.dart` to support offline caching:

   ```dart
   import 'package:flutter/material.dart';
   import 'package:hive_flutter/hive_flutter.dart';
   import 'package:path_provider/path_provider.dart';
   import 'package:connectivity_plus/connectivity_plus.dart';
   import 'package:get/get.dart';
   import 'models/feed_post.dart';
   import 'models/post_comment.dart';
   import 'models/notification.dart';
   import 'models/user_profile.dart';
   
   void main() async {
     WidgetsFlutterBinding.ensureInitialized();
     // Initialize Hive
     final appDocumentDir = await getApplicationDocumentsDirectory();
     await Hive.initFlutter(appDocumentDir.path);
     Hive.registerAdapter(FeedPostAdapter());
     Hive.registerAdapter(NotificationModelAdapter());
     Hive.registerAdapter(UserProfileAdapter());
     Hive.registerAdapter(PostCommentAdapter());
     await Hive.openBox('posts');
     await Hive.openBox('notifications');
     await Hive.openBox('profiles');
     await Hive.openBox('comments');
     await Hive.openBox('post_queue');
   
     // Sync queued actions
     final feedService = Get.find<FeedService>();
     final connectivity = Connectivity();
     if (await connectivity.checkConnectivity() != ConnectivityResult.none) {
       await feedService.syncQueuedPosts();
     }
     connectivity.onConnectivityChanged.listen((result) async {
       if (result != ConnectivityResult.none) {
         await feedService.syncQueuedPosts();
       }
     });
   
     runApp(MyApp());
   }
   ```

## Backend Schema

The Appwrite backend consists of 17 collections, as defined in `lib/models/all_collections_config.json`:

 1. `user_profiles`: User metadata (username, bio, profile picture).
 2. `user_reports`: Reports for flagged content/users.
 3. `blocked_users`: Blocking relationships.
 4. `user_presence`: Online status for DMs.
 5. `chat_messages`: Chat room/DM messages.
 6. `room_participants`: Chat room participants.
 7. `chat_rooms`: Chat room metadata.
 8. `user_names_history`: Historical usernames.
 9. `feed_posts`: Social media posts.
10. `post_comments`: Comments and replies.
11. `post_likes`: Likes for posts/comments/reposts.
12. `post_reposts`: Reposts with optional comments.
13. `hashtags`: Hashtags for discoverability.
14. `bookmarks`: User bookmarks.
15. `follows`: Follow relationships.
16. `activity_logs`: User action history.
17. `notifications`: In-app notifications.

## Feature Implementation Guide

Below are instructions for implementing the 26 features, mapped to your project structure, Appwrite collections, and Hive usage. Each feature includes existing or new Dart files, code snippets, and production-ready best practices.

### 1. Posting Texts

- **Description**: Users create text posts (up to 2000 characters).

- **Collections**: `feed_posts` (`content`, `user_id`, `username`, `room_id`).

- **Dart Files**:

  - `lib/features/social_feed/screens/compose_post_page.dart`
  - `lib/features/social_feed/services/feed_service.dart`
  - `lib/features/social_feed/models/feed_post.dart`
  - `lib/features/social_feed/controllers/feed_controller.dart`

- **Implementation**:

  ```dart
  class FeedService {
    final Databases databases = AppwriteClient.databases;
    final Box postBox = Hive.box('posts');
    final Box queueBox = Hive.box('post_queue');
  
    Future<void> createPost(String userId, String username, String content, String? roomId) async {
      final post = FeedPost(
        id: ID.unique(),
        userId: userId,
        username: username,
        content: content,
        likeCount: 0,
        commentCount: 0,
        createdAt: DateTime.now(),
      );
      try {
        await databases.createDocument(
          databaseId: 'social_media_db',
          collectionId: 'feed_posts',
          documentId: post.id,
          data: post.toJson(),
        );
        final cachedPosts = postBox.get('posts_${roomId ?? 'home'}', defaultValue: []) as List;
        cachedPosts.insert(0, post.toJson());
        await postBox.put('posts_${roomId ?? 'home'}', cachedPosts);
      } catch (e) {
        await queueBox.add(post.toJson());
        final cachedPosts = postBox.get('posts_${roomId ?? 'home'}', defaultValue: []) as List;
        cachedPosts.insert(0, post.toJson());
        await postBox.put('posts_${roomId ?? 'home'}', cachedPosts);
        Get.snackbar('Offline', 'Post queued for syncing');
      }
    }
  
    Future<void> syncQueuedPosts() async {
      final queuedPosts = queueBox.values.toList();
      for (var postJson in queuedPosts) {
        try {
          await databases.createDocument(
            databaseId: 'social_media_db',
            collectionId: 'feed_posts',
            documentId: postJson['$id'],
            data: postJson,
          );
          await queueBox.delete(postJson['$id']);
        } catch (e) {
          print('Failed to sync post: $e');
        }
      }
    }
  }
  ```

  ```dart
  class FeedController extends GetxController {
    final FeedService _feedService = Get.find();
    var posts = <FeedPost>[].obs;
    var isLoading = false.obs;
  
    Future<void> createPost(String content, String? roomId) async {
      final user = Get.find<AuthController>().user;
      try {
        await _feedService.createPost(user.id, user.username, content, roomId);
        await fetchPosts(roomId: roomId);
      } catch (e) {
        print('Error creating post: $e');
      }
    }
  
    Future<void> fetchPosts({String? roomId}) async {
      isLoading.value = true;
      try {
        posts.value = await _feedService.fetchPosts(roomId: roomId);
      } finally {
        isLoading.value = false;
      }
    }
  }
  ```

- **Hive Usage**: Queues posts in `post_queue` for offline sync, caches in `posts`.

- **Production Tips**:

  - Validate content (non-empty, max 2000, sanitize with `html_unescape`).
  - Show “Pending” label for queued posts in `post_card.dart`.
  - Limit queue size (50 posts).
  - Use optimistic UI updates with `Obx` in `compose_post_page.dart`.

### 2. Posting Image

- **Description**: Users upload images to posts, stored in Appwrite Storage.

- **Collections**: `feed_posts` (`media_urls`), Appwrite Storage.

- **Dart Files**:

  - `lib/features/social_feed/screens/compose_post_page.dart`
  - `lib/features/social_feed/services/feed_service.dart`
  - `lib/features/social_feed/models/feed_post.dart`
  - `lib/features/social_feed/widgets/media_gallery.dart`

- **Implementation**:

  ```dart
  Future<String> uploadImage(File image) async {
    final compressed = await FlutterImageCompress.compressAndGetFile(
      image.path,
      '${image.path}_compressed.jpg',
      quality: 80,
    );
    final result = await AppwriteClient.storage.createFile(
      bucketId: 'post_images',
      fileId: ID.unique(),
      file: InputFile.fromPath(path: compressed!.path),
    );
    return 'https://your-appwrite-endpoint/storage/buckets/post_images/files/${result.$id}/view';
  }
  
  Future<void> createPostWithImage(String userId, String username, String content, String? roomId, File image) async {
    try {
      final imageUrl = await uploadImage(image);
      await createPost(userId, username, content, roomId, mediaUrls: [imageUrl]);
    } catch (e) {
      await queueBox.add({
        'action': 'post_with_image',
        'user_id': userId,
        'username': username,
        'content': content,
        'room_id': roomId,
        'image_path': image.path,
      });
      Get.snackbar('Offline', 'Image post queued for syncing');
    }
  }
  ```

- **Hive Usage**: Cache image URLs in `posts` box; queue image paths in `post_queue` for offline uploads.

- **Production Tips**:

  - Compress images with `flutter_image_compress`.
  - Limit file size (10MB) and formats (JPEG, PNG).
  - Use `cached_network_image` in `media_gallery.dart`.
  - Retry failed uploads in `syncQueuedPosts`.

### 3. Posting Link

- **Description**: Users share URLs with metadata previews.

- **Collections**: `feed_posts` (`link_url`, `link_metadata`).

- **Dart Files**:

  - `lib/features/social_feed/screens/compose_post_page.dart`
  - `lib/features/social_feed/services/feed_service.dart`
  - `lib/features/social_feed/widgets/post_card.dart`

- **Implementation**:

  ```dart
  Future<Map<String, dynamic>> fetchLinkMetadata(String url) async {
    final result = await AppwriteClient.functions.createExecution(
      functionId: 'fetch_link_metadata',
      data: jsonEncode({'url': url}),
    );
    return jsonDecode(result.response);
  }
  
  Future<void> createPostWithLink(String userId, String username, String content, String? roomId, String linkUrl) async {
    try {
      final metadata = await fetchLinkMetadata(linkUrl);
      await createPost(userId, username, content, roomId, linkUrl: linkUrl, linkMetadata: jsonEncode(metadata));
    } catch (e) {
      await queueBox.add({
        'action': 'post_with_link',
        'user_id': userId,
        'username': username,
        'content': content,
        'room_id': roomId,
        'link_url': linkUrl,
      });
      Get.snackbar('Offline', 'Link post queued for syncing');
    }
  }
  ```

- **Hive Usage**: Cache `link_metadata` in `posts` box.

- **Production Tips**:

  - Validate URLs with `validators`.
  - Cache metadata in Hive.
  - Display previews in `post_card.dart` with clickable links.
  - Use HTTPS-only URLs.

### 4. Hashtag Identification and Storage

- **Description**: Users add hashtags to posts for discoverability.

- **Collections**: `hashtags`, `feed_posts` (`hashtags`).

- **Dart Files**:

  - `lib/features/social_feed/screens/compose_post_page.dart`
  - `lib/features/social_feed/services/feed_service.dart`
  - New: `lib/features/discovery/screens/hashtag_search_page.dart`
  - New: `lib/features/discovery/models/hashtag.dart`

- **Implementation**:

  ```dart
  Future<void> saveHashtags(List<String> hashtags) async {
    final hashtagBox = Hive.box('hashtags');
    for (var hashtag in hashtags.map((h) => h.toLowerCase())) {
      try {
        final existing = await databases.listDocuments(
          databaseId: 'social_media_db',
          collectionId: 'hashtags',
          queries: [Query.equal('hashtag', hashtag)],
        );
        if (existing.documents.isNotEmpty) {
          await databases.updateDocument(
            databaseId: 'social_media_db',
            collectionId: 'hashtags',
            documentId: existing.documents[0].$id,
            data: {
              'usage_count': existing.documents[0].data['usage_count'] + 1,
              'last_used_at': DateTime.now().toIso8601String(),
            },
          );
        } else {
          await databases.createDocument(
            databaseId: 'social_media_db',
            collectionId: 'hashtags',
            documentId: ID.unique(),
            data: {
              'hashtag': hashtag,
              'usage_count': 1,
              'last_used_at': DateTime.now().toIso8601String(),
            },
          );
        }
        hashtagBox.put(hashtag, {'hashtag': hashtag, 'last_used_at': DateTime.now().toIso8601String()});
      } catch (e) {
        hashtagBox.put(hashtag, {'hashtag': hashtag, 'last_used_at': DateTime.now().toIso8601String()});
      }
    }
  }
  ```

  ```dart
  class HashtagSearchPage extends StatelessWidget {
    final String hashtag;
    const HashtagSearchPage({required this.hashtag});
  
    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(title: Text('#$hashtag')),
        body: GetBuilder<FeedController>(
          builder: (controller) {
            controller.searchPostsByHashtag(hashtag);
            return Obx(() => controller.isLoading.value
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: controller.posts.length,
                    itemBuilder: (context, index) => PostCard(post: controller.posts[index]),
                  ));
          },
        ),
      );
    }
  }
  ```

- **Hive Usage**: Cache trending hashtags in `hashtags` box.

- **Production Tips**:

  - Normalize hashtags (lowercase, no spaces).
  - Limit hashtags per post (10).
  - Use fulltext index for `hashtags`.
  - Make hashtags clickable in `post_card.dart`.

### 5. Displaying Post

- **Description**: Users view posts in feeds (home, profile, hashtag).

- **Collections**: `feed_posts`, `user_profiles`.

- **Dart Files**:

  - `lib/features/social_feed/screens/feed_page.dart`
  - `lib/features/social_feed/services/feed_service.dart`
  - `lib/features/social_feed/widgets/post_card.dart`
  - `lib/features/social_feed/controllers/feed_controller.dart`

- **Implementation**:

  ```dart
  Future<List<FeedPost>> fetchPosts({String? roomId, int limit = 20, String? cursor}) async {
    final postBox = Hive.box('posts');
    try {
      final queries = [Query.limit(limit)];
      if (roomId != null) queries.add(Query.equal('room_id', roomId));
      if (cursor != null) queries.add(Query.cursorAfter(cursor));
      final result = await databases.listDocuments(
        databaseId: 'social_media_db',
        collectionId: 'feed_posts',
        queries: queries,
      );
      final posts = result.documents.map((doc) => FeedPost.fromJson(doc.data)).toList();
      await postBox.put('posts_${roomId ?? 'home'}', posts.map((p) => p.toJson()).toList());
      return posts;
    } catch (e) {
      final cached = postBox.get('posts_${roomId ?? 'home'}', defaultValue: []);
      return cached.map((json) => FeedPost.fromJson(json)).toList();
    }
  }
  ```

- **Hive Usage**: Cache posts in `posts` box for offline viewing.

- **Production Tips**:

  - Use `CachedNetworkImage` in `post_card.dart`.

  - Implement infinite scrolling in `feed_page.dart`.

  - Filter `is_deleted: true` posts server-side.

  - Subscribe to `feed_posts` for real-time updates:

    ```dart
    AppwriteClient.realtime.subscribe(['databases.social_media_db.collections.feed_posts.documents']).listen((event) {
      Get.find<FeedController>().fetchPosts();
    });
    ```

### 6. Like/Unlike Post

- **Description**: Users like or unlike posts, updating like count.

- **Collections**: `post_likes`, `feed_posts` (`like_count`).

- **Dart Files**:

  - `lib/features/social_feed/services/feed_service.dart`
  - `lib/features/social_feed/widgets/reaction_bar.dart`
  - `lib/features/social_feed/controllers/feed_controller.dart`

- **Implementation**:

  ```dart
  Future<void> likePost(String userId, String postId) async {
    final queueBox = Hive.box('post_queue');
    try {
      await databases.createDocument(
        databaseId: 'social_media_db',
        collectionId: 'post_likes',
        documentId: ID.unique(),
        data: {'item_id': postId, 'item_type': 'post', 'user_id': userId},
      );
      await AppwriteClient.functions.createExecution(
        functionId: 'increment_like_count',
        data: jsonEncode({'post_id': postId}),
      );
    } catch (e) {
      await queueBox.add({'action': 'like', 'user_id': userId, 'post_id': postId});
      Get.snackbar('Offline', 'Like queued for syncing');
    }
  }
  ```

- **Hive Usage**: Queue likes in `post_queue` for offline sync.

- **Production Tips**:

  - Use optimistic updates in `reaction_bar.dart`.
  - Handle duplicates with `user_item_unique` index.
  - Subscribe to `post_likes` for real-time counts.
  - Show error snackbars.

### 7. Repost and Undo Repost

- **Description**: Users repost posts with optional comments.

- **Collections**: `post_reposts`, `feed_posts` (`repost_count`).

- **Dart Files**:

  - New: `lib/features/social_feed/screens/repost_page.dart`
  - `lib/features/social_feed/services/feed_service.dart`
  - `lib/features/social_feed/widgets/reaction_bar.dart`

- **Implementation**:

  ```dart
  Future<void> repost(String userId, String postId, String? comment) async {
    final queueBox = Hive.box('post_queue');
    try {
      await databases.createDocument(
        databaseId: 'social_media_db',
        collectionId: 'post_reposts',
        documentId: ID.unique(),
        data: {'post_id': postId, 'user_id': userId, 'comment': comment},
      );
      await AppwriteClient.functions.createExecution(
        functionId: 'increment_repost_count',
        data: jsonEncode({'post_id': postId}),
      );
      if (comment != null) {
        await NotificationService(databases).createNotification(
          (await databases.getDocument(databaseId: 'social_media_db', collectionId: 'feed_posts', documentId: postId)).data['user_id'],
          userId,
          'repost',
          itemId: postId,
          itemType: 'post',
        );
      }
    } catch (e) {
      await queueBox.add({'action': 'repost', 'user_id': userId, 'post_id': postId, 'comment': comment});
      Get.snackbar('Offline', 'Repost queued for syncing');
    }
  }
  ```

- **Hive Usage**: Queue reposts in `post_queue`.

- **Production Tips**:

  - Use optimistic updates in `reaction_bar.dart`.
  - Handle duplicates with `user_post_unique` index.
  - Validate comment length (max 2000).
  - Show repost attribution in `post_card.dart`.

### 8. Bookmarking Posts, Undo Bookmark

- **Description**: Users bookmark posts for later viewing.

- **Collections**: `bookmarks`.

- **Dart Files**:

  - New: `lib/features/bookmarks/screens/bookmark_list_page.dart`
  - `lib/features/social_feed/services/feed_service.dart`
  - `lib/features/social_feed/widgets/reaction_bar.dart`
  - New: `lib/features/bookmarks/controllers/bookmark_controller.dart`

- **Implementation**:

  ```dart
  Future<void> bookmarkPost(String userId, String postId) async {
    final bookmarkBox = Hive.box('bookmarks');
    try {
      await databases.createDocument(
        databaseId: 'social_media_db',
        collectionId: 'bookmarks',
        documentId: ID.unique(),
        data: {'user_id': userId, 'post_id': postId, 'created_at': DateTime.now().toIso8601String()},
      );
      bookmarkBox.put('$userId_$postId', {'post_id': postId});
    } catch (e) {
      bookmarkBox.put('$userId_$postId', {'post_id': postId});
      Get.snackbar('Offline', 'Bookmark saved locally');
    }
  }
  ```

  ```dart
  class BookmarkController extends GetxController {
    var bookmarks = <FeedPost>[].obs;
    var isLoading = false.obs;
  
    Future<void> fetchBookmarks(String userId) async {
      isLoading.value = true;
      try {
        final result = await databases.listDocuments(
          databaseId: 'social_media_db',
          collectionId: 'bookmarks',
          queries: [Query.equal('user_id', userId)],
        );
        final postIds = result.documents.map((doc) => doc.data['post_id']).toList();
        final posts = await databases.listDocuments(
          databaseId: 'social_media_db',
          collectionId: 'feed_posts',
          queries: [Query.equal('$id', postIds)],
        );
        bookmarks.value = posts.documents.map((doc) => FeedPost.fromJson(doc.data)).toList();
        Hive.box('posts').put('bookmarks_$userId', bookmarks.map((p) => p.toJson()).toList());
      } catch (e) {
        final cached = Hive.box('posts').get('bookmarks_$userId', defaultValue: []);
        bookmarks.value = cached.map((json) => FeedPost.fromJson(json)).toList();
      } finally {
        isLoading.value = false;
      }
    }
  }
  ```

- **Hive Usage**: Cache bookmarks in `bookmarks` box; cache bookmarked posts in `posts`.

- **Production Tips**:

  - Use optimistic updates.
  - Handle deleted posts (`is_deleted` check).
  - Restrict access with `read("users")`.
  - Integrate with `modern_profile_page.dart`.

### 9. Commenting on Main Posts

- **Description**: Users comment on posts.

- **Collections**: `post_comments` (`post_id`, `content`), `feed_posts` (`comment_count`).

- **Dart Files**:

  - `lib/features/social_feed/screens/comment_thread_page.dart`
  - `lib/features/social_feed/services/feed_service.dart`
  - `lib/features/social_feed/widgets/comment_card.dart`
  - `lib/features/social_feed/controllers/comments_controller.dart`

- **Implementation**:

  ```dart
  Future<void> createComment(String userId, String username, String postId, String content) async {
    final commentBox = Hive.box('comments');
    final queueBox = Hive.box('post_queue');
    try {
      final comment = await databases.createDocument(
        databaseId: 'social_media_db',
        collectionId: 'post_comments',
        documentId: ID.unique(),
        data: {
          'post_id': postId,
          'user_id': userId,
          'username': username,
          'content': content,
          'createdAt': DateTime.now().toIso8601String(),
          'like_count': 0,
          'reply_count': 0,
          'is_deleted': false,
        },
      );
      await AppwriteClient.functions.createExecution(
        functionId: 'increment_comment_count',
        data: jsonEncode({'post_id': postId}),
      );
      commentBox.put(comment.$id, comment.data);
      final post = await databases.getDocument(databaseId: 'social_media_db', collectionId: 'feed_posts', documentId: postId);
      if (post.data['user_id'] != userId) {
        await NotificationService(databases).createNotification(
          post.data['user_id'],
          userId,
          'comment',
          itemId: postId,
          itemType: 'post',
        );
      }
    } catch (e) {
      final commentId = ID.unique();
      commentBox.put(commentId, {
        '$id': commentId,
        'post_id': postId,
        'user_id': userId,
        'username': username,
        'content': content,
        'createdAt': DateTime.now().toIso8601String(),
      });
      queueBox.add({'action': 'comment', 'comment_id': commentId, 'post_id': postId, 'user_id': userId, 'content': content});
      Get.snackbar('Offline', 'Comment queued for syncing');
    }
  }
  ```

- **Hive Usage**: Cache comments in `comments` box, queue in `post_queue`.

- **Production Tips**:

  - Validate comment length (max 2000).
  - Use optimistic updates in `comment_card.dart`.
  - Subscribe to `post_comments` for real-time.
  - Sanitize content with `html_unescape`.

### 10. Replying

- **Description**: Users reply to comments, creating threads.

- **Collections**: `post_comments` (`parent_id`).

- **Dart Files**: Same as Commenting on Main Posts.

- **Implementation**:

  ```dart
  Future<void> createReply(String userId, String username, String postId, String parentId, String content) async {
    final commentBox = Hive.box('comments');
    final queueBox = Hive.box('post_queue');
    try {
      final reply = await databases.createDocument(
        databaseId: 'social_media_db',
        collectionId: 'post_comments',
        documentId: ID.unique(),
        data: {
          'post_id': postId,
          'user_id': userId,
          'username': username,
          'parent_id': parentId,
          'content': content,
          'createdAt': DateTime.now().toIso8601String(),
          'like_count': 0,
          'reply_count': 0,
          'is_deleted': false,
        },
      );
      await AppwriteClient.functions.createExecution(
        functionId: 'increment_reply_count',
        data: jsonEncode({'comment_id': parentId}),
      );
      commentBox.put(reply.$id, reply.data);
      final parentComment = await databases.getDocument(databaseId: 'social_media_db', collectionId: 'post_comments', documentId: parentId);
      if (parentComment.data['user_id'] != userId) {
        await NotificationService(databases).createNotification(
          parentComment.data['user_id'],
          userId,
          'reply',
          itemId: postId,
          itemType: 'comment',
        );
      }
    } catch (e) {
      final replyId = ID.unique();
      commentBox.put(replyId, {
        '$id': replyId,
        'post_id': postId,
        'user_id': userId,
        'username': username,
        'parent_id': parentId,
        'content': content,
        'createdAt': DateTime.now().toIso8601String(),
      });
      queueBox.add({'action': 'reply', 'reply_id': replyId, 'post_id': postId, 'parent_id': parentId, 'user_id': userId, 'content': content});
      Get.snackbar('Offline', 'Reply queued for syncing');
    }
  }
  ```

- **Hive Usage**: Cache replies in `comments` box, queue in `post_queue`.

- **Production Tips**:

  - Limit nesting depth (5 levels) in `comment_thread_page.dart`.
  - Lazy load deep threads.
  - Handle deleted parent comments.
  - Ensure accessibility in `comment_card.dart`.

### 11. Comments Thread

- **Description**: Display comments in a threaded structure.

- **Collections**: `post_comments` (`parent_id`).

- **Dart Files**:

  - `lib/features/social_feed/screens/comment_thread_page.dart`
  - `lib/features/social_feed/widgets/comment_card.dart`

- **Implementation**:

  ```dart
  class CommentThread extends StatelessWidget {
    final PostComment comment;
    final List<PostComment> replies;
  
    const CommentThread({required this.comment, required this.replies});
  
    @override
    Widget build(BuildContext context) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CommentCard(comment: comment),
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Column(
              children: replies
                  .map((reply) => CommentThread(
                        comment: reply,
                        replies: Get.find<CommentsController>().getReplies(reply.id),
                      ))
                  .toList(),
            ),
          ),
        ],
      );
    }
  }
  ```

- **Hive Usage**: Cache threads in `comments` box.

- **Production Tips**:

  - Optimize queries for top-level comments.
  - Use `realtime.subscribe` for new replies.
  - Paginate large threads in `comment_thread_page.dart`.
  - Ensure accessibility.

### 12. Replying on Comments Thread

- **Description**: Users reply to replies in threads.
- **Collections**: `post_comments` (`parent_id`).
- **Dart Files**: Same as Replying.
- **Implementation**: Same as Replying.
- **Hive Usage**: Same as Replying.
- **Production Tips**: Same as Replying.

### 13. Liking Reposts and Comments

- **Description**: Users like reposts and comments.

- **Collections**: `post_likes` (`item_type: repost`, `item_type: comment`).

- **Dart Files**:

  - `lib/features/social_feed/services/feed_service.dart`
  - `lib/features/social_feed/widgets/reaction_bar.dart`
  - `lib/features/social_feed/widgets/comment_card.dart`

- **Implementation**:

  ```dart
  Future<void> likeComment(String userId, String commentId) async {
    final queueBox = Hive.box('post_queue');
    try {
      await databases.createDocument(
        databaseId: 'social_media_db',
        collectionId: 'post_likes',
        documentId: ID.unique(),
        data: {'item_id': commentId, 'item_type': 'comment', 'user_id': userId},
      );
      await AppwriteClient.functions.createExecution(
        functionId: 'increment_comment_like_count',
        data: jsonEncode({'comment_id': commentId}),
      );
      final comment = await databases.getDocument(databaseId: 'social_media_db', collectionId: 'post_comments', documentId: commentId);
      if (comment.data['user_id'] != userId) {
        await NotificationService(databases).createNotification(
          comment.data['user_id'],
          userId,
          'like',
          itemId: commentId,
          itemType: 'comment',
        );
      }
    } catch (e) {
      await queueBox.add({'action': 'like_comment', 'user_id': userId, 'comment_id': commentId});
      Get.snackbar('Offline', 'Comment like queued for syncing');
    }
  }
  ```

- **Hive Usage**: Queue likes in `post_queue`.

- **Production Tips**:

  - Use optimistic updates.
  - Handle duplicates.
  - Subscribe to `post_likes`.
  - Show error feedback in `reaction_bar.dart`.

### 14. Follow User

- **Description**: Users follow others to see their posts.

- **Collections**: `follows`.

- **Dart Files**:

  - `lib/pages/profile_page.dart` or `lib/new_codes_to_implement/modern_profile_page.dart`
  - New: `lib/features/profile/services/profile_service.dart`
  - New: `lib/features/profile/controllers/profile_controller.dart`
  - New: `lib/features/profile/models/user_profile.dart`

- **Implementation**:

  ```dart
  class ProfileService {
    final Databases databases = AppwriteClient.databases;
    final Box profileBox = Hive.box('profiles');
  
    Future<void> followUser(String followerId, String followedId) async {
      final followsBox = Hive.box('follows');
      try {
        await databases.createDocument(
          databaseId: 'social_media_db',
          collectionId: 'follows',
          documentId: ID.unique(),
          data: {'follower_id': followerId, 'followed_id': followedId, 'created_at': DateTime.now().toIso8601String()},
        );
        followsBox.put('$followerId_$followedId', {'followed_id': followedId});
        await NotificationService(databases).createNotification(followedId, followerId, 'follow');
      } catch (e) {
        followsBox.put('$followerId_$followedId', {'followed_id': followedId});
        Get.snackbar('Offline', 'Follow saved locally');
      }
    }
  
    Future<UserProfile> fetchProfile(String userId) async {
      try {
        final result = await databases.getDocument(
          databaseId: 'social_media_db',
          collectionId: 'user_profiles',
          documentId: userId,
        );
        final profile = UserProfile.fromJson(result.data);
        await profileBox.put(userId, profile.toJson());
        return profile;
      } catch (e) {
        final cached = profileBox.get(userId);
        if (cached != null) return UserProfile.fromJson(cached);
        throw Exception('Failed to fetch profile: $e');
      }
    }
  }
  ```

  ```dart
  class ProfileController extends GetxController {
    var profile = Rxn<UserProfile>();
    var isLoading = false.obs;
  
    Future<void> loadProfile(String userId) async {
      isLoading.value = true;
      try {
        profile.value = await Get.find<ProfileService>().fetchProfile(userId);
      } finally {
        isLoading.value = false;
      }
    }
  
    Future<void> followUser(String followedId) async {
      final user = Get.find<AuthController>().user;
      await Get.find<ProfileService>().followUser(user.id, followedId);
    }
  }
  ```

- **Hive Usage**: Cache follows in `follows` box; cache profiles in `profiles`.

- **Production Tips**:

  - Use optimistic updates in `modern_profile_page.dart`.
  - Cache followed IDs for offline feed.
  - Handle private accounts (`is_private`).
  - Show follower counts.

### 15. Search Users

- **Description**: Users search by username or bio.

- **Collections**: `user_profiles`, `user_names_history`.

- **Dart Files**:

  - New: `lib/features/search/screens/search_page.dart`
  - New: `lib/features/search/services/search_service.dart`
  - New: `lib/features/search/controllers/search_controller.dart`

- **Implementation**:

  ```dart
  class SearchService {
    final Databases databases = AppwriteClient.databases;
    final Box profileBox = Hive.box('profiles');
  
    Future<List<UserProfile>> searchUsers(String query) async {
      try {
        final profiles = await databases.listDocuments(
          databaseId: 'social_media_db',
          collectionId: 'user_profiles',
          queries: [Query.search('username', query), Query.search('bio', query)],
        );
        final history = await databases.listDocuments(
          databaseId: 'social_media_db',
          collectionId: 'user_names_history',
          queries: [Query.search('username', query)],
        );
        final userIds = history.documents.map((doc) => doc.data['userId']).toSet();
        final additionalProfiles = await databases.listDocuments(
          databaseId: 'social_media_db',
          collectionId: 'user_profiles',
          queries: [Query.equal('$id', userIds.toList())],
        );
        final results = [...profiles.documents, ...additionalProfiles.documents]
            .map((doc) => UserProfile.fromJson(doc.data))
            .toList();
        for (var profile in results) {
          profileBox.put(profile.id, profile.toJson());
        }
        return results;
      } catch (e) {
        final cached = profileBox.values
            .map((json) => UserProfile.fromJson(json))
            .where((profile) => profile.username.toLowerCase().contains(query.toLowerCase()) || (profile.bio?.toLowerCase().contains(query.toLowerCase()) ?? false))
            .toList();
        return cached;
      }
    }
  }
  ```

  ```dart
  class SearchController extends GetxController {
    var searchResults = <UserProfile>[].obs;
    var isLoading = false.obs;
  
    Future<void> searchUsers(String query) async {
      if (query.isEmpty) return;
      isLoading.value = true;
      try {
        searchResults.value = await Get.find<SearchService>().searchUsers(query);
      } finally {
        isLoading.value = false;
      }
    }
  }
  ```

- **Hive Usage**: Cache profiles in `profiles` box.

- **Production Tips**:

  - Debounce search input in `search_page.dart`.
  - Use fulltext indexes.
  - Cache recent searches in Hive.
  - Handle case-insensitivity.

### 16. Editing Posts for 30 Minutes

- **Description**: Users edit posts within 30 minutes.

- **Collections**: `feed_posts` (`is_edited`, `edited_at`).

- **Dart Files**:

  - New: `lib/features/social_feed/screens/edit_post_page.dart`
  - `lib/features/social_feed/services/feed_service.dart`
  - `lib/features/social_feed/widgets/post_card.dart`

- **Implementation**:

  ```dart
  Future<void> editPost(String postId, String content, List<String> hashtags, List<String> mentions) async {
    final postBox = Hive.box('posts');
    try {
      final post = await databases.getDocument(
        databaseId: 'social_media_db',
        collectionId: 'feed_posts',
        documentId: postId,
      );
      if (DateTime.now().difference(DateTime.parse(post.data['createdAt'])).inMinutes > 30) {
        throw Exception('Edit window expired');
      }
      await databases.updateDocument(
        databaseId: 'social_media_db',
        collectionId: 'feed_posts',
        documentId: postId,
        data: {
          'content': content,
          'hashtags': hashtags,
          'mentions': mentions,
          'is_edited': true,
          'edited_at': DateTime.now().toIso8601String(),
        },
      );
      final cachedPosts = postBox.get('posts_home', defaultValue: []) as List;
      final index = cachedPosts.indexWhere((p) => p['$id'] == postId);
      if (index != -1) {
        cachedPosts[index] = {...cachedPosts[index], 'content': content, 'hashtags': hashtags, 'mentions': mentions, 'is_edited': true};
        await postBox.put('posts_home', cachedPosts);
      }
    } catch (e) {
      throw Exception('Failed to edit post: $e');
    }
  }
  ```

- **Hive Usage**: Update cached posts in `posts` box.

- **Production Tips**:

  - Enforce 30-minute limit server-side.
  - Validate updated content in `edit_post_page.dart`.
  - Show “Edited” label in `post_card.dart`.
  - Use optimistic updates.

### 17. Deleting Posts, Comments

- **Description**: Users soft delete their posts/comments.

- **Collections**: `feed_posts` (`is_deleted`), `post_comments` (`is_deleted`).

- **Dart Files**:

  - `lib/features/social_feed/services/feed_service.dart`
  - `lib/features/social_feed/widgets/post_card.dart`
  - `lib/features/social_feed/widgets/comment_card.dart`

- **Implementation**:

  ```dart
  Future<void> deletePost(String postId) async {
    final postBox = Hive.box('posts');
    try {
      await databases.updateDocument(
        databaseId: 'social_media_db',
        collectionId: 'feed_posts',
        documentId: postId,
        data: {'is_deleted': true},
      );
      final cachedPosts = postBox.get('posts_home', defaultValue: []) as List;
      final index = cachedPosts.indexWhere((p) => p['$id'] == postId);
      if (index != -1) {
        cachedPosts[index]['is_deleted'] = true;
        await postBox.put('posts_home', cachedPosts);
      }
    } catch (e) {
      throw Exception('Failed to delete post: $e');
    }
  }
  ```

- **Hive Usage**: Update `is_deleted` in `posts` or `comments` box.

- **Production Tips**:

  - Confirm deletion with dialog in `post_card.dart`.
  - Cascade soft deletes for comments via Appwrite Function.
  - Allow undo within 5 minutes.
  - Restrict to owners.

### 18. Flag Posts

- **Description**: Users report posts for moderation.

- **Collections**: `user_reports` (`reported_post_id`).

- **Dart Files**:

  - New: `lib/features/social_feed/screens/report_post_page.dart`
  - New: `lib/features/social_feed/services/report_service.dart`
  - `lib/features/social_feed/widgets/post_card.dart`

- **Implementation**:

  ```dart
  class ReportService {
    final Databases databases = AppwriteClient.databases;
  
    Future<void> reportPost(String reporterId, String postId, String reportType, String description) async {
      try {
        await databases.createDocument(
          databaseId: 'social_media_db',
          collectionId: 'user_reports',
          documentId: ID.unique(),
          data: {
            'reporter_id': reporterId,
            'reported_post_id': postId,
            'report_type': reportType,
            'description': description,
            'status': 'pending',
          },
        );
        Get.snackbar('Reported', 'Post reported for review');
      } catch (e) {
        throw Exception('Failed to report post: $e');
      }
    }
  }
  ```

- **Hive Usage**: Not applicable (requires online submission).

- **Production Tips**:

  - Limit report frequency (5/day) via Appwrite Function.
  - Validate report type (enum: spam, harassment, nudity).
  - Show confirmation snackbar.
  - Restrict to authenticated users.

### 19. Flag Users

- **Description**: Users report other users.

- **Collections**: `user_reports` (`reported_user_id`).

- **Dart Files**:

  - New: `lib/features/profile/screens/report_user_page.dart`
  - `lib/features/profile/services/report_service.dart`
  - `lib/pages/profile_page.dart` or `lib/new_codes_to_implement/modern_profile_page.dart`

- **Implementation**:

  ```dart
  Future<void> reportUser(String reporterId, String reportedUserId, String reportType, String description) async {
    try {
      await databases.createDocument(
        databaseId: 'social_media_db',
        collectionId: 'user_reports',
        documentId: ID.unique(),
        data: {
          'reporter_id': reporterId,
          'reported_user_id': reportedUserId,
          'report_type': reportType,
          'description': description,
          'status': 'pending',
        },
      );
      Get.snackbar('Reported', 'User reported for review');
    } catch (e) {
      throw Exception('Failed to report user: $e');
    }
  }
  ```

- **Hive Usage**: Not applicable.

- **Production Tips**:

  - Prevent self-reporting.
  - Notify moderators via admin dashboard.
  - Restrict read access to `team:moderators`.
  - Provide appeal mechanism.

### 20. Block Users

- **Description**: Users block others to prevent interactions.

- **Collections**: `blocked_users`.

- **Dart Files**:

  - `lib/pages/profile_page.dart` or `lib/new_codes_to_implement/modern_profile_page.dart`
  - `lib/features/profile/services/profile_service.dart`
  - `lib/features/profile/controllers/profile_controller.dart`

- **Implementation**:

  ```dart
  Future<void> blockUser(String blockerId, String blockedId, String? reason) async {
    final blockBox = Hive.box('blocks');
    try {
      await databases.createDocument(
        databaseId: 'social_media_db',
        collectionId: 'blocked_users',
        documentId: ID.unique(),
        data: {'blocker_id': blockerId, 'blocked_id': blockedId, 'reason': reason},
      );
      blockBox.put('$blockerId_$blockedId', {'blocked_id': blockedId});
    } catch (e) {
      blockBox.put('$blockerId_$blockedId', {'blocked_id': blockedId});
      Get.snackbar('Offline', 'Block saved locally');
    }
  }
  ```

- **Hive Usage**: Cache blocks in `blocks` box for offline filtering.

- **Production Tips**:

  - Confirm blocking with dialog.
  - Filter blocked content server-side in `feed_service.dart`.
  - Handle duplicates with unique index.
  - Cache blocked IDs.

### 21. Mentions/Tagging Users

- **Description**: Users tag others with @username.

- **Collections**: `feed_posts` (`mentions`), `post_comments` (`content`).

- **Dart Files**:

  - `lib/features/social_feed/screens/compose_post_page.dart`
  - `lib/features/social_feed/screens/comment_thread_page.dart`
  - `lib/features/social_feed/services/feed_service.dart`

- **Implementation**:

  ```dart
  Future<void> createPostWithMentions(String userId, String username, String content, String? roomId) async {
    final mentions = RegExp(r'@[a-zA-Z0-9_]+').allMatches(content).map((m) => m.group(0)!.substring(1)).toList();
    final postId = ID.unique();
    await createPost(userId, username, content, roomId, mentions: mentions, postId: postId);
    for (var mention in mentions) {
      final user = await databases.listDocuments(
        databaseId: 'social_media_db',
        collectionId: 'user_profiles',
        queries: [Query.equal('username', mention)],
      );
      if (user.documents.isNotEmpty) {
        await NotificationService(databases).createNotification(
          user.documents[0].data['$id'],
          userId,
          'mention',
          itemId: postId,
          itemType: 'post',
        );
      }
    }
  }
  ```

- **Hive Usage**: Cache mentions in `posts` or `comments` box.

- **Production Tips**:

  - Validate usernames in `user_profiles`.
  - Limit mentions (10).
  - Make mentions clickable in `post_card.dart` and `comment_card.dart`.
  - Notify mentioned users.

### 22. Content Sharing Outside the App

- **Description**: Users share posts externally.

- **Collections**: `feed_posts` (`share_count`).

- **Dart Files**:

  - `lib/features/social_feed/screens/feed_page.dart`
  - `lib/features/social_feed/services/feed_service.dart`
  - `lib/features/social_feed/widgets/reaction_bar.dart`

- **Implementation**:

  ```dart
  Future<String> sharePost(String postId) async {
    try {
      await AppwriteClient.functions.createExecution(
        functionId: 'increment_share_count',
        data: jsonEncode({'post_id': postId}),
      );
      return 'https://your-app.com/post/$postId';
    } catch (e) {
      throw Exception('Failed to share post: $e');
    }
  }
  
  void sharePostLink(String postId) async {
    try {
      final link = await Get.find<FeedService>().sharePost(postId);
      await Share.share('Check out this post: $link');
    } catch (e) {
      Get.snackbar('Error', 'Failed to share post');
    }
  }
  ```

- **Hive Usage**: Cache shareable links in `posts` box.

- **Production Tips**:

  - Generate short URLs via Appwrite Function.
  - Track shares in `activity_logs`.
  - Handle private posts (`is_private`).
  - Support deep links in `main.dart`.

### 23. Content Moderation

- **Description**: Moderators review flagged content.

- **Collections**: `user_reports`.

- **Dart Files**:

  - New: `lib/features/admin/screens/moderation_dashboard.dart`
  - New: `lib/features/admin/services/moderation_service.dart`
  - New: `lib/features/admin/controllers/moderation_controller.dart`

- **Implementation**:

  ```dart
  class ModerationService {
    final Databases databases = AppwriteClient.databases;
  
    Future<List<Report>> fetchPendingReports() async {
      final result = await databases.listDocuments(
        databaseId: 'social_media_db',
        collectionId: 'user_reports',
        queries: [Query.equal('status', 'pending')],
      );
      return result.documents.map((doc) => Report.fromJson(doc.data)).toList();
    }
  
    Future<void> reviewReport(String reportId, String moderatorId, String actionTaken) async {
      await databases.updateDocument(
        databaseId: 'social_media_db',
        collectionId: 'user_reports',
        documentId: reportId,
        data: {
          'status': 'reviewed',
          'reviewed_by': moderatorId,
          'reviewed_at': DateTime.now().toIso8601String(),
          'action_taken': actionTaken,
        },
      );
    }
  }
  ```

  ```dart
  class Report {
    final String id;
    final String reporterId;
    final String? reportedPostId;
    final String? reportedUserId;
    final String reportType;
    final String description;
    final String status;
  
    Report({
      required this.id,
      required this.reporterId,
      this.reportedPostId,
      this.reportedUserId,
      required this.reportType,
      required this.description,
      required this.status,
    });
  
    factory Report.fromJson(Map<String, dynamic> json) {
      return Report(
        id: json['$id'],
        reporterId: json['reporter_id'],
        reportedPostId: json['reported_post_id'],
        reportedUserId: json['reported_user_id'],
        reportType: json['report_type'],
        description: json['description'],
        status: json['status'],
      );
    }
  }
  ```

- **Hive Usage**: Not applicable.

- **Production Tips**:

  - Use Appwrite Teams for moderator roles.
  - Log actions in `activity_logs`.
  - Notify users of outcomes.
  - Implement audit trails.

### 24. Feed Algorithms

- **Description**: Sort feeds by chronological, most commented, or most liked.
- **Sort Modes**:
  - *Chronological*: Oldest to newest.
  - *Most Recent*: Newest to oldest.

- **Collections**: `feed_posts` (`like_count`, `comment_count`).

- **Dart Files**:

  - `lib/features/social_feed/screens/feed_page.dart`
  - `lib/features/social_feed/services/feed_service.dart`
  - `lib/features/social_feed/controllers/feed_controller.dart`

- **Implementation**:

  ```dart
  Future<List<FeedPost>> fetchSortedPosts(String sortType, {String? roomId}) async {
    final postBox = Hive.box('posts');
    final queries = [Query.limit(20)];
    if (roomId != null) queries.add(Query.equal('room_id', roomId));
    switch (sortType) {
      case 'chronological':
      case 'most-recent':
        queries.add(Query.orderDesc('$createdAt'));
        break;
      case 'most-commented':
        queries.add(Query.orderDesc('comment_count'));
        break;
      case 'most-liked':
        queries.add(Query.orderDesc('like_count'));
        break;
    }
    try {
      final result = await databases.listDocuments(
        databaseId: 'social_media_db',
        collectionId: 'feed_posts',
        queries: queries,
      );
      final posts = result.documents.map((doc) => FeedPost.fromJson(doc.data)).toList();
      await postBox.put('posts_${sortType}_${roomId ?? 'home'}', posts.map((p) => p.toJson()).toList());
      return posts;
    } catch (e) {
      final cached = postBox.get('posts_${sortType}_${roomId ?? 'home'}', defaultValue: []);
      return cached.map((json) => FeedPost.fromJson(json)).toList();
    }
  }
  ```

- **Hive Usage**: Cache sorted feeds in `posts` box.

- **Production Tips**:

  - Cache sort preferences in Hive.
  - Use indexes (`most_liked`, `most_commented`).
  - Allow algorithm toggling in `feed_page.dart`.
  - Paginate feeds.

### 25. Activity Logs

- **Description**: Track user actions for profile history.

- **Collections**: `activity_logs`.

- **Dart Files**:

  - New: `lib/features/profile/screens/activity_log_page.dart`
  - New: `lib/features/profile/services/activity_service.dart`
  - New: `lib/features/profile/controllers/activity_controller.dart`

- **Implementation**:

  ```dart
  class ActivityService {
    final Databases databases = AppwriteClient.databases;
    final Box activityBox = Hive.box('activities');
  
    Future<void> logActivity(String userId, String actionType, {String? itemId, String? itemType}) async {
      try {
        final log = await databases.createDocument(
          databaseId: 'social_media_db',
          collectionId: 'activity_logs',
          documentId: ID.unique(),
          data: {
            'user_id': userId,
            'action_type': actionType,
            'item_id': itemId,
            'item_type': itemType,
            'created_at': DateTime.now().toIso8601String(),
          },
        );
        activityBox.put(log.$id, log.data);
      } catch (e) {
        activityBox.add({
          'user_id': userId,
          'action_type': actionType,
          'item_id': itemId,
          'item_type': itemType,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    }
  }
  ```

- **Hive Usage**: Cache logs in `activities` box.

- **Production Tips**:

  - Limit retention (30 days) via Appwrite Function.
  - Cache recent logs.
  - Group similar actions in `activity_log_page.dart`.
  - Restrict access with `read("users")`.

### 26. In-App Notifications and App Icon Badges

- **Description**: Display in-app notifications with app icon badges for unread counts.

- **Collections**: `notifications`, `chat_messages`.

- **Dart Files**:

  - New: `lib/features/notifications/screens/notification_page.dart`
  - New: `lib/features/notifications/services/notification_service.dart`
  - New: `lib/features/notifications/controllers/notification_controller.dart`
  - New: `lib/features/notifications/models/notification.dart`
  - New: `lib/widgets/bottom_nav_bar.dart` (or update existing navigation)

- **Implementation**:

  ```dart
  class NotificationService {
    final Databases databases = AppwriteClient.databases;
    final Box notificationBox = Hive.box('notifications');
  
    Future<void> createNotification(String userId, String actorId, String actionType, {String? itemId, String? itemType}) async {
      try {
        final notification = await databases.createDocument(
          databaseId: 'social_media_db',
          collectionId: 'notifications',
          documentId: ID.unique(),
          data: {
            'user_id': userId,
            'actor_id': actorId,
            'action_type': actionType,
            'item_id': itemId,
            'item_type': itemType,
            'is_read': false,
            'created_at': DateTime.now().toIso8601String(),
          },
        );
        final cached = notificationBox.get('notifications_$userId', defaultValue: []) as List;
        cached.insert(0, notification.data);
        await notificationBox.put('notifications_$userId', cached);
        await notificationBox.put('unread_count_$userId', cached.where((n) => !n['is_read']).length);
        updateAppBadge(cached.where((n) => !n['is_read']).length);
      } catch (e) {
        throw Exception('Failed to create notification: $e');
      }
    }
  
    Future<List<NotificationModel>> fetchNotifications(String userId) async {
      try {
        final result = await databases.listDocuments(
          databaseId: 'social_media_db',
          collectionId: 'notifications',
          queries: [Query.equal('user_id', userId), Query.orderDesc('created_at'), Query.limit(50)],
        );
        final notifications = result.documents.map((doc) => NotificationModel.fromJson(doc.data)).toList();
        await notificationBox.put('notifications_$userId', notifications.map((n) => n.toJson()).toList());
        await notificationBox.put('unread_count_$userId', notifications.where((n) => !n.isRead).length);
        updateAppBadge(notifications.where((n) => !n.isRead).length);
        return notifications;
      } catch (e) {
        final cached = notificationBox.get('notifications_$userId', defaultValue: []);
        final notifications = cached.map((json) => NotificationModel.fromJson(json)).toList();
        updateAppBadge(notifications.where((n) => !n.isRead).length);
        return notifications;
      }
    }
  
    Future<void> markAsRead(String notificationId) async {
      try {
        await databases.updateDocument(
          databaseId: 'social_media_db',
          collectionId: 'notifications',
          documentId: notificationId,
          data: {'is_read': true},
        );
        final userId = Get.find<AuthController>().user.id;
        final cached = notificationBox.get('notifications_$userId', defaultValue: []) as List;
        final index = cached.indexWhere((n) => n['$id'] == notificationId);
        if (index != -1) {
          cached[index]['is_read'] = true;
          await notificationBox.put('notifications_$userId', cached);
          await notificationBox.put('unread_count_$userId', cached.where((n) => !n['is_read']).length);
          updateAppBadge(cached.where((n) => !n['is_read']).length);
        }
      } catch (e) {
        throw Exception('Failed to mark notification as read: $e');
      }
    }
  }
  ```

  ```dart
  import 'package:flutter_app_badge/flutter_app_badge.dart';
  
  void updateAppBadge(int count) {
    if (count > 0) {
      FlutterAppBadge.updateBadge(count);
    } else {
      FlutterAppBadge.removeBadge();
    }
  }
  ```

  ```dart
  class NotificationController extends GetxController {
    var notifications = <NotificationModel>[].obs;
    var unreadCount = 0.obs;
    var isLoading = false.obs;
  
    Future<void> loadNotifications(String userId) async {
      isLoading.value = true;
      try {
        notifications.value = await Get.find<NotificationService>().fetchNotifications(userId);
        unreadCount.value = notifications.where((n) => !n.isRead).length;
      } finally {
        isLoading.value = false;
      }
    }
  
    Future<void> markAsRead(String notificationId) async {
      await Get.find<NotificationService>().markAsRead(notificationId);
      final index = notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        notifications[index] = notifications[index].copyWith(isRead: true);
        unreadCount.value = notifications.where((n) => !n.isRead).length;
      }
    }
  }
  ```

  ```dart
  class NotificationPage extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
      final controller = Get.find<NotificationController>();
      return Scaffold(
        appBar: AppBar(title: Text('Notifications')),
        body: Obx(() => controller.isLoading.value
            ? Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: controller.notifications.length,
                itemBuilder: (context, index) {
                  final notification = controller.notifications[index];
                  return ListTile(
                    leading: Icon(_getIconForAction(notification.actionType)),
                    title: Text('${notification.actorId} ${notification.actionType}d your ${notification.itemType ?? 'content'}'),
                    subtitle: Text(notification.createdAt.toString()),
                    trailing: notification.isRead ? null : Icon(Icons.circle, color: Colors.blue, size: 10),
                    onTap: () async {
                      if (!notification.isRead) {
                        await controller.markAsRead(notification.id);
                        if (notification.itemType == 'post' && notification.itemId != null) {
                          Get.toNamed('/post', arguments: notification.itemId);
                        }
                      }
                    },
                  );
                },
              )),
      );
    }
  
    IconData _getIconForAction(String actionType) {
      switch (actionType) {
        case 'comment': return Icons.comment;
        case 'like': return Icons.favorite;
        case 'follow': return Icons.person_add;
        case 'repost': return Icons.repeat;
        case 'mention': return Icons.alternate_email;
        case 'message': return Icons.message;
        default: return Icons.notifications;
      }
    }
  }
  ```

  ```dart
  class BottomNavBar extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
      final notificationController = Get.find<NotificationController>();
      return Obx(() => BottomNavigationBar(
            items: [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(
                icon: Stack(
                  children: [
                    Icon(Icons.notifications),
                    if (notificationController.unreadCount.value > 0)
                      Positioned(
                        right: 0,
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          child: Text(
                            '${notificationController.unreadCount.value}',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ),
                  ],
                ),
                label: 'Notifications',
              ),
            ],
            onTap: (index) {
              if (index == 0) Get.toNamed('/home');
              if (index == 1) Get.toNamed('/notifications');
            },
          ));
    }
  }
  ```

  ```dart
  AppwriteClient.realtime.subscribe(['databases.social_media_db.collections.notifications.documents']).listen((event) {
    final payload = event.payload;
    if (payload['user_id'] == Get.find<AuthController>().user.id) {
      Get.find<NotificationController>().notifications.insert(0, NotificationModel.fromJson(payload));
      if (!payload['is_read']) {
        Get.find<NotificationController>().unreadCount.value++;
        updateAppBadge(Get.find<NotificationController>().unreadCount.value);
      }
    }
  });
  ```

- **Hive Usage**: Cache notifications in `notifications` box for offline access.

- **Production Tips**:

  - Paginate notifications in `notification_page.dart`.
  - Group similar notifications (e.g., “5 users liked your post”).
  - Add notification preferences to `user_profiles` (`notification_settings` JSON).
  - Ensure accessibility with semantic labels.
  - Log views in `activity_logs` via `activity_service.dart`.
  - Use `flutter_local_notifications` for Android badge compatibility if needed.

## Production-Ready Best Practices

1. **Error Handling**:
   - Use try-catch blocks for all API calls.
   - Show user-friendly snackbars via `Get.snackbar`.
   - Log errors to `activity_logs` using `activity_service.dart`.
2. **Performance**:
   - Paginate API queries (limit: 50).
   - Cache data with Hive (expire after 7-30 days).
   - Use lazy loading for large datasets (e.g., feeds, comments).
   - Debounce search inputs in `search_page.dart`.
3. **Security**:
   - Sanitize inputs with `html_unescape`.
   - Respect Appwrite permissions (verify in backend review).
   - Encrypt sensitive Hive data (e.g., profiles) with `flutter_secure_storage`.
   - Validate inputs server-side via Appwrite Functions.
4. **Offline Support**:
   - Cache viewable data (posts, comments, notifications, profiles) in Hive.
   - Queue actions (posts, likes, comments) in `post_queue`.
   - Sync with Appwrite when online using `connectivity_plus`.
5. **Real-Time Updates**:
   - Subscribe to collections (`feed_posts`, `post_comments`, `notifications`) with `realtime.subscribe`.
   - Update Hive cache on real-time events.
6. **Accessibility**:
   - Add semantic labels for screen readers in `post_card.dart`, `comment_card.dart`.
   - Ensure high-contrast UI with `modern_ui_system.dart`.
   - Support dynamic text sizes.
7. **Testing**:
   - Update `test/features/social_feed/feed_controller_test.dart` and `post_card_test.dart`.
   - Add tests for new controllers (`notification_controller_test.dart`, `profile_controller_test.dart`).
   - Test offline scenarios with network disabled.
   - Verify Realtime updates and badge counts on iOS/Android emulators.

## Next Steps

1. **Backend Review**:
   - AI agent to verify Appwrite collections against `lib/models/all_collections_config.json`.
   - Report discrepancies to the developer.
2. **Code Implementation**:
   - Create new files as specified (e.g., `notification_page.dart`, `profile_service.dart`).
   - Update existing files (`feed_service.dart`, `post_card.dart`) with new functionality.
   - Integrate modernized UI pages from `lib/new_codes_to_implement/`.
3. **Testing**:
   - Run existing tests in `test/`.
   - Add new tests for implemented features.
   - Test offline scenarios and Realtime updates.

This guide ensures a robust, production-ready implementation of StarChat’s social media features, leveraging the existing project structure and Appwrite backend.
