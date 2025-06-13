import 'dart:convert';

class FeedPost {
  final String id;
  final String roomId;
  final String userId;
  final String username;
  final String? userAvatar;
  final String content;
  final List<String> mediaUrls;
  final String? pollId;
  final String? linkUrl;
  final Map<String, dynamic>? linkMetadata;
  final int likeCount;
  final int commentCount;
  final int repostCount;
  final int shareCount;
  final List<String> hashtags;

  FeedPost({
    required this.id,
    required this.roomId,
    required this.userId,
    required this.username,
    this.userAvatar,
    required this.content,
    this.mediaUrls = const [],
    this.pollId,
    this.linkUrl,
    this.linkMetadata,
    this.likeCount = 0,
    this.commentCount = 0,
    this.repostCount = 0,
    this.shareCount = 0,
    this.hashtags = const [],
  });

  factory FeedPost.fromJson(Map<String, dynamic> json) {
    return FeedPost(
      id: json['\$id'] ?? json['id'],
      roomId: json['room_id'] ?? '',
      userId: json['user_id'] ?? '',
      username: json['username'] ?? '',
      userAvatar: json['user_avatar'],
      content: json['content'] ?? '',
      mediaUrls: (json['media_urls'] as List?)?.cast<String>() ?? const [],
      pollId: json['poll_id'],
      linkUrl: json['link_url'],
      linkMetadata: _parseMetadata(json['link_metadata']),
      likeCount: json['like_count'] ?? 0,
      commentCount: json['comment_count'] ?? 0,
      repostCount: json['repost_count'] ?? 0,
      shareCount: json['share_count'] ?? 0,
      hashtags: (json['hashtags'] as List?)?.cast<String>() ?? const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'room_id': roomId,
      'user_id': userId,
      'username': username,
      'user_avatar': userAvatar,
      'content': content,
      'media_urls': mediaUrls,
      'poll_id': pollId,
      'link_url': linkUrl,
      'link_metadata': linkMetadata,
      'like_count': likeCount,
      'comment_count': commentCount,
      'repost_count': repostCount,
      'share_count': shareCount,
      'hashtags': hashtags,
    };
  }

  static Map<String, dynamic>? _parseMetadata(dynamic raw) {
    if (raw == null) return null;
    if (raw is Map<String, dynamic>) return raw;
    if (raw is String && raw.isNotEmpty) {
      try {
        return jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}
