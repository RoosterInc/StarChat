class FeedPost {
  final String id;
  final String roomId;
  final String userId;
  final String username;
  final String? userAvatar;
  final String content;
  final List<String> mediaUrls;
  final String? pollId;
  final int likeCount;
  final int commentCount;
  final int repostCount;
  final int shareCount;

  FeedPost({
    required this.id,
    required this.roomId,
    required this.userId,
    required this.username,
    this.userAvatar,
    required this.content,
    this.mediaUrls = const [],
    this.pollId,
    this.likeCount = 0,
    this.commentCount = 0,
    this.repostCount = 0,
    this.shareCount = 0,
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
      likeCount: json['like_count'] ?? 0,
      commentCount: json['comment_count'] ?? 0,
      repostCount: json['repost_count'] ?? 0,
      shareCount: json['share_count'] ?? 0,
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
      'like_count': likeCount,
      'comment_count': commentCount,
      'repost_count': repostCount,
      'share_count': shareCount,
    };
  }
}
