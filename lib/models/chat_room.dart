import 'package:flutter/material.dart';
import '../utils/parsing_utils.dart';

class ChatRoom {
  final String id;
  final String name;
  final String type;
  final String? rashiId;
  final String? symbol;
  final int dailyMessages;
  final List<Color> gradientColors;
  final DateTime? lastMessageAt;
  final bool isActive;

  ChatRoom({
    required this.id,
    required this.name,
    required this.type,
    this.rashiId,
    this.symbol,
    required this.dailyMessages,
    required this.gradientColors,
    this.lastMessageAt,
    this.isActive = true,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['id'] ?? json['\$id'],
      name: json['name'],
      type: json['type'],
      rashiId: json['rashi_id'],
      symbol: json['symbol'],
      dailyMessages: json['daily_messages'] ?? 0,
      gradientColors: [
        Color(json['color_primary'] ?? 0xFFFF6B6B),
        Color(json['color_secondary'] ?? 0xFFFF8E8E),
      ],
      lastMessageAt: json['last_message_at'] != null
          ? ParsingUtils.parseDateTime(json['last_message_at'])
          : null,
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'rashi_id': rashiId,
      'symbol': symbol,
      'daily_messages': dailyMessages,
      'color_primary': gradientColors.first.value,
      'color_secondary': gradientColors.last.value,
      'last_message_at': lastMessageAt?.toIso8601String(),
      'is_active': isActive,
    };
  }
}
