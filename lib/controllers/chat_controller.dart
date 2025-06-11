import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:get/get.dart';
import 'package:appwrite/appwrite.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../utils/logger.dart';
import '../utils/modern_color_palettes.dart';

import '../models/chat_room.dart';
import 'auth_controller.dart';

class ChatController extends GetxController {
  final AuthController _auth = Get.find<AuthController>();

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
      _createModernMockRashiRooms();
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

  void _createModernMockRashiRooms() {
    // Modern, sophisticated color palettes based on 2024-2025 UI trends
    final modernGradients = [
      // Aries - Warm coral to soft peach
      [const Color(0xFFFF9A9E), const Color(0xFFFECFEF)],

      // Taurus - Earth green to sage
      [const Color(0xFF83A4D4), const Color(0xFFB6FBFF)],

      // Gemini - Sky blue to lavender
      [const Color(0xFFA8EDEA), const Color(0xFFFED6E3)],

      // Cancer - Soft purple to pink
      [const Color(0xFFD299C2), const Color(0xFFFED6E3)],

      // Leo - Golden yellow to orange
      [const Color(0xFFFDC830), const Color(0xFFF37335)],

      // Virgo - Mint to teal
      [const Color(0xFF4FACFE), const Color(0xFF00F2FE)],

      // Libra - Rose to coral
      [const Color(0xFFF093FB), const Color(0xFFF5576C)],

      // Scorpio - Deep purple to magenta
      [const Color(0xFF4E54C8), const Color(0xFF8F94FB)],

      // Sagittarius - Turquoise to blue
      [const Color(0xFF43E97B), const Color(0xFF38F9D7)],

      // Capricorn - Gray blue to light blue
      [const Color(0xFF667EEA), const Color(0xFF764BA2)],

      // Aquarius - Electric blue to cyan
      [const Color(0xFF2196F3), const Color(0xFF21CBF3)],

      // Pisces - Ocean blue to aqua
      [const Color(0xFF36D1DC), const Color(0xFF5B86E5)],
    ];

    final rashiData = [
      {'name': 'Aries Rashi', 'symbol': '♈', 'messages': 142},
      {'name': 'Taurus Rashi', 'symbol': '♉', 'messages': 98},
      {'name': 'Gemini Rashi', 'symbol': '♊', 'messages': 156},
      {'name': 'Cancer Rashi', 'symbol': '♋', 'messages': 89},
      {'name': 'Leo Rashi', 'symbol': '♌', 'messages': 203},
      {'name': 'Virgo Rashi', 'symbol': '♍', 'messages': 76},
      {'name': 'Libra Rashi', 'symbol': '♎', 'messages': 134},
      {'name': 'Scorpio Rashi', 'symbol': '♏', 'messages': 167},
      {'name': 'Sagittarius Rashi', 'symbol': '♐', 'messages': 92},
      {'name': 'Capricorn Rashi', 'symbol': '♑', 'messages': 118},
      {'name': 'Aquarius Rashi', 'symbol': '♒', 'messages': 145},
      {'name': 'Pisces Rashi', 'symbol': '♓', 'messages': 101},
    ];

    rashiRooms.assignAll(
      rashiData.asMap().entries.map((entry) {
        final index = entry.key;
        final data = entry.value;

        return ChatRoom(
          id: (index + 1).toString(),
          name: data['name'] as String,
          type: 'rashi',
          symbol: data['symbol'] as String,
          dailyMessages: data['messages'] as int,
          gradientColors: modernGradients[index],
        );
      }).toList(),
    );

    logger
        .i('Created modern mock rashi rooms with sophisticated color palettes');
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

/// Modern glassmorphism utility functions
class GlassmorphismUtils {
  /// Create a modern glassmorphism container
  static Widget createGlassContainer({
    required Widget child,
    double borderRadius = 20,
    double blur = 10,
    List<Color>? gradientColors,
    bool isDark = false,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors ??
                  [
                    Colors.white.withOpacity(isDark ? 0.1 : 0.2),
                    Colors.white.withOpacity(isDark ? 0.05 : 0.1),
                  ],
            ),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  /// Create modern elevation shadow
  static List<BoxShadow> createModernShadow(Color baseColor, double elevation) {
    return [
      BoxShadow(
        color: baseColor.withOpacity(0.2),
        blurRadius: elevation,
        offset: Offset(0, elevation / 2),
      ),
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: elevation * 2,
        offset: Offset(0, elevation),
      ),
    ];
  }
}
