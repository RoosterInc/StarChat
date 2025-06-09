import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:appwrite/appwrite.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';

import '../models/chat_room.dart';
import 'auth_controller.dart';

class ChatController extends GetxController {
  final AuthController _auth = Get.find<AuthController>();
  final logger = Logger();

  final RxList<ChatRoom> rashiRooms = <ChatRoom>[].obs;
  final RxList<ChatRoom> joinedRooms = <ChatRoom>[].obs;
  final Rx<ChatRoom?> currentRoom = Rx<ChatRoom?>(null);

  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;

  @override
  void onInit() {
    super.onInit();
    initializeChatRooms();
  }

  Future<void> initializeChatRooms() async {
    isLoading.value = true;
    error.value = '';
    try {
      await _loadRashiRooms();
      logger.i('Chat rooms loaded: \${rashiRooms.length}');
    } catch (e) {
      error.value = e.toString();
      logger.e('Error loading chat rooms', error: e);
      _createMockRashiRooms();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadRashiRooms() async {
    final dbId = dotenv.env['APPWRITE_DATABASE_ID'] ?? 'StarChat_DB';
    const collectionId = 'chat_rooms';
    final result = await _auth.databases.listDocuments(
      databaseId: dbId,
      collectionId: collectionId,
      queries: [
        Query.equal('type', 'rashi'),
        Query.equal('is_active', true),
        Query.orderAsc('order'),
      ],
    );
    final rooms =
        result.documents.map((doc) => ChatRoom.fromJson(doc.data)).toList();
    rashiRooms.assignAll(rooms);
  }

  void _createMockRashiRooms() {
    rashiRooms.assignAll([
      ChatRoom(
        id: '1',
        name: 'Aries Rashi',
        type: 'rashi',
        symbol: '♈',
        dailyMessages: 142,
        gradientColors: [Color(0xFFFF6B6B), Color(0xFFFF8E8E)],
      ),
      ChatRoom(
        id: '2',
        name: 'Taurus Rashi',
        type: 'rashi',
        symbol: '♉',
        dailyMessages: 98,
        gradientColors: [Color(0xFF4ECDC4), Color(0xFF7EDDD4)],
      ),
      ChatRoom(
        id: '3',
        name: 'Gemini Rashi',
        type: 'rashi',
        symbol: '♊',
        dailyMessages: 156,
        gradientColors: [Color(0xFF45B7D1), Color(0xFF75C7E1)],
      ),
      ChatRoom(
        id: '4',
        name: 'Cancer Rashi',
        type: 'rashi',
        symbol: '♋',
        dailyMessages: 89,
        gradientColors: [Color(0xFF96CEB4), Color(0xFFB6DEC4)],
      ),
      ChatRoom(
        id: '5',
        name: 'Leo Rashi',
        type: 'rashi',
        symbol: '♌',
        dailyMessages: 203,
        gradientColors: [Color(0xFFFFA726), Color(0xFFFFB74D)],
      ),
      ChatRoom(
        id: '6',
        name: 'Virgo Rashi',
        type: 'rashi',
        symbol: '♍',
        dailyMessages: 76,
        gradientColors: [Color(0xFF8E24AA), Color(0xFFAB47BC)],
      ),
      ChatRoom(
        id: '7',
        name: 'Libra Rashi',
        type: 'rashi',
        symbol: '♎',
        dailyMessages: 134,
        gradientColors: [Color(0xFFE91E63), Color(0xFFF06292)],
      ),
      ChatRoom(
        id: '8',
        name: 'Scorpio Rashi',
        type: 'rashi',
        symbol: '♏',
        dailyMessages: 167,
        gradientColors: [Color(0xFF5D4037), Color(0xFF8D6E63)],
      ),
      ChatRoom(
        id: '9',
        name: 'Sagittarius Rashi',
        type: 'rashi',
        symbol: '♐',
        dailyMessages: 92,
        gradientColors: [Color(0xFF00ACC1), Color(0xFF26C6DA)],
      ),
      ChatRoom(
        id: '10',
        name: 'Capricorn Rashi',
        type: 'rashi',
        symbol: '♑',
        dailyMessages: 118,
        gradientColors: [Color(0xFF6D4C41), Color(0xFF8D6E63)],
      ),
      ChatRoom(
        id: '11',
        name: 'Aquarius Rashi',
        type: 'rashi',
        symbol: '♒',
        dailyMessages: 145,
        gradientColors: [Color(0xFF42A5F5), Color(0xFF64B5F6)],
      ),
      ChatRoom(
        id: '12',
        name: 'Pisces Rashi',
        type: 'rashi',
        symbol: '♓',
        dailyMessages: 101,
        gradientColors: [Color(0xFF26A69A), Color(0xFF4DB6AC)],
      ),
    ]);
    logger.i('Created mock rashi rooms');
  }

  ChatRoom? getRoomById(String roomId) {
    return rashiRooms.firstWhereOrNull((r) => r.id == roomId);
  }

  Future<void> refreshRooms() async {
    await initializeChatRooms();
  }

  Future<void> joinRoom(String roomId) async {
    final room = getRoomById(roomId);
    if (room != null && !joinedRooms.contains(room)) {
      joinedRooms.add(room);
    }
  }

  Future<void> leaveRoom(String roomId) async {
    joinedRooms.removeWhere((r) => r.id == roomId);
  }
}
