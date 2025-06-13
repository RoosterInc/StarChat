class NotificationModel {
  final String id;
  final String userId;
  final String actorId;
  final String actionType;
  final String? itemId;
  final String? itemType;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.actorId,
    required this.actionType,
    this.itemId,
    this.itemType,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['\$id'] ?? json['id'],
      userId: json['user_id'],
      actorId: json['actor_id'],
      actionType: json['action_type'],
      itemId: json['item_id'],
      itemType: json['item_type'],
      isRead: json['is_read'] as bool,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        '\$id': id,
        'user_id': userId,
        'actor_id': actorId,
        'action_type': actionType,
        'item_id': itemId,
        'item_type': itemType,
        'is_read': isRead,
        'created_at': createdAt.toIso8601String(),
      };

  NotificationModel copyWith({bool? isRead}) => NotificationModel(
        id: id,
        userId: userId,
        actorId: actorId,
        actionType: actionType,
        itemId: itemId,
        itemType: itemType,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
      );
}
