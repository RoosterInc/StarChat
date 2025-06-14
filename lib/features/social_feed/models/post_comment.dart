class PostComment {
  final String id;
  final String postId;
  final String userId;
  final String username;
  final String? userAvatar;
  final String? parentId;
  final String content;
  final List<String> mediaUrls;
  final int likeCount;
  final int replyCount;
  final bool isDeleted;

  PostComment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.username,
    this.userAvatar,
    this.parentId,
    required this.content,
    this.mediaUrls = const [],
    this.likeCount = 0,
    this.replyCount = 0,
    this.isDeleted = false,
  });

  factory PostComment.fromJson(Map<String, dynamic> json) {
    return PostComment(
      id: json['\$id'] ?? json['id'],
      postId: json['post_id'],
      userId: json['user_id'],
      username: json['username'] ?? '',
      userAvatar: json['user_avatar'],
      parentId: json['parent_id'],
      content: json['content'] ?? '',
      mediaUrls: (json['media_urls'] as List?)?.cast<String>() ?? const [],
      likeCount: json['like_count'] ?? 0,
      replyCount: json['reply_count'] ?? 0,
      isDeleted: json['is_deleted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'post_id': postId,
      'user_id': userId,
      'username': username,
      'user_avatar': userAvatar,
      'parent_id': parentId,
      'content': content,
      'media_urls': mediaUrls,
      'like_count': likeCount,
      'reply_count': replyCount,
      'is_deleted': isDeleted,
    };
  }
}
