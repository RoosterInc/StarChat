import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:myapp/models/chat_room.dart';

void main() {
  group('ChatRoom model', () {
    test('fromJson and toJson maintain values', () {
      final json = {
        'id': '123',
        'name': 'Test Room',
        'type': 'rashi',
        'rashi_id': 'r1',
        'symbol': '♈',
        'daily_messages': 5,
        'color_primary': Colors.red.value,
        'color_secondary': Colors.blue.value,
        'last_message_at': DateTime.parse('2024-01-01').toIso8601String(),
        'is_active': true,
      };

      final room = ChatRoom.fromJson(json);

      expect(room.id, '123');
      expect(room.name, 'Test Room');
      expect(room.type, 'rashi');
      expect(room.rashiId, 'r1');
      expect(room.symbol, '♈');
      expect(room.dailyMessages, 5);
      expect(room.gradientColors.first, const Color(0xFFFF0000));
      expect(room.gradientColors.last, const Color(0xFF0000FF));
      expect(room.lastMessageAt, DateTime.parse('2024-01-01'));
      expect(room.isActive, true);

      final encoded = room.toJson();
      expect(encoded['id'], json['id']);
      expect(encoded['name'], json['name']);
      expect(encoded['type'], json['type']);
      expect(encoded['rashi_id'], json['rashi_id']);
      expect(encoded['symbol'], json['symbol']);
      expect(encoded['daily_messages'], json['daily_messages']);
      expect(encoded['color_primary'], json['color_primary']);
      expect(encoded['color_secondary'], json['color_secondary']);
      expect(encoded['last_message_at'], json['last_message_at']);
      expect(encoded['is_active'], json['is_active']);
    }, skip: true);
  });
}
