class PostRepost {
  final String id;
  final String postId;
  final String userId;
  final String? comment;

  PostRepost({
    required this.id,
    required this.postId,
    required this.userId,
    this.comment,
  });

  factory PostRepost.fromJson(Map<String, dynamic> json) {
    return PostRepost(
      id: json['\$id'] ?? json['id'],
      postId: json['post_id'],
      userId: json['user_id'],
      comment: json['comment'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'post_id': postId,
      'user_id': userId,
      'comment': comment,
    };
  }
}
