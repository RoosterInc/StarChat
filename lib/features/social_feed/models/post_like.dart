class PostLike {
  final String id;
  final String itemId;
  final String itemType;
  final String userId;

  PostLike({
    required this.id,
    required this.itemId,
    required this.itemType,
    required this.userId,
  });

  factory PostLike.fromJson(Map<String, dynamic> json) {
    return PostLike(
      id: json['\$id'] ?? json['id'],
      itemId: json['item_id'],
      itemType: json['item_type'],
      userId: json['user_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item_id': itemId,
      'item_type': itemType,
      'user_id': userId,
    };
  }
}
