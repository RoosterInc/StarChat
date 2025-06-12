class PollVote {
  final String id;
  final String pollId;
  final String userId;
  final int optionIndex;

  PollVote({
    required this.id,
    required this.pollId,
    required this.userId,
    required this.optionIndex,
  });

  factory PollVote.fromJson(Map<String, dynamic> json) {
    return PollVote(
      id: json['\$id'] ?? json['id'],
      pollId: json['poll_id'],
      userId: json['user_id'],
      optionIndex: json['option_index'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'poll_id': pollId,
      'user_id': userId,
      'option_index': optionIndex,
    };
  }
}
