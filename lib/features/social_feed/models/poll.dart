class Poll {
  final String id;
  final String postId;
  final String question;
  final List<String> options;
  final DateTime? expiresAt;
  final int totalVotes;

  Poll({
    required this.id,
    required this.postId,
    required this.question,
    required this.options,
    this.expiresAt,
    this.totalVotes = 0,
  });

  factory Poll.fromJson(Map<String, dynamic> json) {
    return Poll(
      id: json['\$id'] ?? json['id'],
      postId: json['post_id'],
      question: json['question'] ?? '',
      options: (json['options'] as List?)?.cast<String>() ?? const [],
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'])
          : null,
      totalVotes: json['total_votes'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'post_id': postId,
      'question': question,
      'options': options,
      'expires_at': expiresAt?.toIso8601String(),
      'total_votes': totalVotes,
    };
  }
}
