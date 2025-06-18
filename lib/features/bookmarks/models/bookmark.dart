import "../../social_feed/models/feed_post.dart";

class Bookmark {
  final String id;
  final String postId;
  final String userId;
  final DateTime createdAt;

  Bookmark({
    required this.id,
    required this.postId,
    required this.userId,
    required this.createdAt,
  });

  factory Bookmark.fromJson(Map<String, dynamic> json) {
    return Bookmark(
      id: json['\$id'] ?? json['id'],
      postId: json['post_id'],
      userId: json['user_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'post_id': postId,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class BookmarkedPost {
  final Bookmark bookmark;
  final FeedPost post;

  BookmarkedPost({required this.bookmark, required this.post});

  factory BookmarkedPost.fromMap(Map<String, dynamic> map) {
    return BookmarkedPost(
      bookmark: Bookmark.fromJson(Map<String, dynamic>.from(map['bookmark'])),
      post: FeedPost.fromJson(Map<String, dynamic>.from(map['post'])),
    );
  }

  Map<String, dynamic> toMap() => {
        'bookmark': bookmark.toJson(),
        'post': post.toJson(),
      };
}
