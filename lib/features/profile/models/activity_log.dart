class ActivityLog {
  final String id;
  final String userId;
  final String actionType;
  final String? itemId;
  final String? itemType;
  final DateTime createdAt;

  ActivityLog({
    required this.id,
    required this.userId,
    required this.actionType,
    this.itemId,
    this.itemType,
    required this.createdAt,
  });

  factory ActivityLog.fromJson(Map<String, dynamic> json) => ActivityLog(
        id: json['\$id'] ?? json['id'],
        userId: json['user_id'],
        actionType: json['action_type'],
        itemId: json['item_id'],
        itemType: json['item_type'],
        createdAt: DateTime.parse(json['created_at']),
      );

  Map<String, dynamic> toJson() => {
        '\$id': id,
        'user_id': userId,
        'action_type': actionType,
        'item_id': itemId,
        'item_type': itemType,
        'created_at': createdAt.toIso8601String(),
      };
}
