class PostComment {
  final String id;
  final String postId;
  final String userId;
  final String username;
  final String? userAvatar;
  final String? parentId;
  final String content;
  final List<String> mediaUrls;
  final List<String> mentions;
  final int likeCount;
  final int replyCount;
  final bool isDeleted;
  final bool isEdited;
  final DateTime? editedAt;

  PostComment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.username,
    this.userAvatar,
    this.parentId,
    required this.content,
    this.mediaUrls = const [],
    this.mentions = const [],
    this.likeCount = 0,
    this.replyCount = 0,
    this.isDeleted = false,
    this.isEdited = false,
    this.editedAt,
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
      mentions: (json['mentions'] as List?)?.cast<String>() ?? const [],
      likeCount: json['like_count'] ?? 0,
      replyCount: json['reply_count'] ?? 0,
      isDeleted: json['is_deleted'] ?? false,
      isEdited: json['is_edited'] ?? false,
      editedAt: json['edited_at'] != null
          ? DateTime.tryParse(json['edited_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson({bool includeId = true, bool includeMentions = true}) {
    return {
      if (includeId) 'id': id,
      'post_id': postId,
      'user_id': userId,
      'username': username,
      'user_avatar': userAvatar,
      'parent_id': parentId,
      'content': content,
      'media_urls': mediaUrls,
      if (includeMentions) 'mentions': mentions,
      'like_count': likeCount,
      'reply_count': replyCount,
      'is_deleted': isDeleted,
      'is_edited': isEdited,
      'edited_at': editedAt?.toIso8601String(),
    };
  }
}
