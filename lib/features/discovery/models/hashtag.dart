class Hashtag {
  final String id;
  final String hashtag;
  final int usageCount;
  final DateTime? lastUsedAt;

  Hashtag({
    required this.id,
    required this.hashtag,
    this.usageCount = 1,
    this.lastUsedAt,
  });

  factory Hashtag.fromJson(Map<String, dynamic> json) {
    return Hashtag(
      id: json['\$id'] ?? json['id'],
      hashtag: json['hashtag'] ?? '',
      usageCount: json['usage_count'] ?? 1,
      lastUsedAt: json['last_used_at'] != null
          ? DateTime.tryParse(json['last_used_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'hashtag': hashtag,
        'usage_count': usageCount,
        'last_used_at': lastUsedAt?.toIso8601String(),
      };
}
