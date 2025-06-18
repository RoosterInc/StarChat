import 'package:flutter/material.dart';

/// Modern, sophisticated color palettes for chat rooms
/// Based on 2024-2025 UI design trends with glassmorphism in mind
class ModernColorPalettes {
  
  // Sophisticated gradient palettes with better contrast and accessibility
  static const List<List<Color>> rashiGradients = [
    // Aries - Warm coral to soft peach
    [Color(0xFFFF9A9E), Color(0xFFFECFEF)],
    
    // Taurus - Earth green to sage
    [Color(0xFF83A4D4), Color(0xFFB6FBFF)],
    
    // Gemini - Sky blue to lavender
    [Color(0xFFA8EDEA), Color(0xFFFED6E3)],
    
    // Cancer - Soft purple to pink
    [Color(0xFFD299C2), Color(0xFFFED6E3)],
    
    // Leo - Golden yellow to orange
    [Color(0xFFFDC830), Color(0xFFF37335)],
    
    // Virgo - Mint to teal
    [Color(0xFF4FACFE), Color(0xFF00F2FE)],
    
    // Libra - Rose to coral
    [Color(0xFFF093FB), Color(0xFFF5576C)],
    
    // Scorpio - Deep purple to magenta
    [Color(0xFF4E54C8), Color(0xFF8F94FB)],
    
    // Sagittarius - Turquoise to blue
    [Color(0xFF43E97B), Color(0xFF38F9D7)],
    
    // Capricorn - Gray blue to light blue
    [Color(0xFF667EEA), Color(0xFF764BA2)],
    
    // Aquarius - Electric blue to cyan
    [Color(0xFF2196F3), Color(0xFF21CBF3)],
    
    // Pisces - Ocean blue to aqua
    [Color(0xFF36D1DC), Color(0xFF5B86E5)],
  ];

  // Alternative sophisticated palettes for variety
  static const List<List<Color>> alternativeGradients = [
    // Warm sunset
    [Color(0xFFFA8072), Color(0xFFFFB6C1)],
    
    // Cool ocean
    [Color(0xFF74B9FF), Color(0xFF81ECEC)],
    
    // Forest whisper
    [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
    
    // Lavender dream
    [Color(0xFFE17055), Color(0xFFFDCB6E)],
    
    // Golden hour
    [Color(0xFF00B894), Color(0xFF55EFC4)],
    
    // Mystic purple
    [Color(0xFFF8B500), Color(0xFFFFD93D)],
    
    // Cherry blossom
    [Color(0xFF00CEFF), Color(0xFF0099FF)],
    
    // Northern lights
    [Color(0xFF667EEA), Color(0xFF764BA2)],
    
    // Emerald sea
    [Color(0xFF12C2E9), Color(0xFFC471ED)],
    
    // Rose gold
    [Color(0xFFFE6B8B), Color(0xFFFF8E53)],
    
    // Cosmic blue
    [Color(0xFF667DB6), Color(0xFF0082C8)],
    
    // Gentle breeze
    [Color(0xFF89F7FE), Color(0xFF66A6FF)],
  ];

  // Glassmorphism-friendly background colors
  static const List<Color> backgroundColors = [
    Color(0xFFF8F9FA), // Light gray
    Color(0xFFF1F3F4), // Cool gray
    Color(0xFFF5F7FA), // Blue-tinted white
    Color(0xFFFAFBFC), // Pure light
    Color(0xFFF0F2F5), // Facebook-style light
  ];

  // Dark mode friendly backgrounds
  static const List<Color> darkBackgroundColors = [
    Color(0xFF1A1A1A), // Rich black
    Color(0xFF0F1419), // Dark blue
    Color(0xFF121212), // Material dark
    Color(0xFF1E1E1E), // VS Code dark
    Color(0xFF0D1117), // GitHub dark
  ];

  /// Get a sophisticated gradient pair for a given index
  static List<Color> getGradientForIndex(int index) {
    return rashiGradients[index % rashiGradients.length];
  }

  /// Get an alternative gradient for variety
  static List<Color> getAlternativeGradient(int index) {
    return alternativeGradients[index % alternativeGradients.length];
  }

  /// Create a softer version of a color for better accessibility
  static Color softenColor(Color color, {double opacity = 0.8}) {
    return Color.lerp(color, Colors.white, 1 - opacity) ?? color;
  }

  /// Create a color with better contrast for text
  static Color getTextColor(List<Color> backgroundGradient, {bool isDark = false}) {
    // Calculate luminance to determine best text color
    final avgLuminance = (backgroundGradient.first.computeLuminance() + 
                         backgroundGradient.last.computeLuminance()) / 2;
    
    if (avgLuminance > 0.5) {
      return isDark ? Colors.white : Colors.black87;
    } else {
      return Colors.white;
    }
  }

  /// Get glassmorphism overlay colors
  static List<Color> getGlassmorphismOverlay({bool isDark = false}) {
    if (isDark) {
      return [
        Colors.white.withOpacity(0.1),
        Colors.white.withOpacity(0.05),
      ];
    } else {
      return [
        Colors.white.withOpacity(0.25),
        Colors.white.withOpacity(0.15),
      ];
    }
  }

  /// Generate a modern shadow color from a base color
  static BoxShadow createModernShadow(Color baseColor, {double elevation = 4}) {
    return BoxShadow(
      color: baseColor.withOpacity(0.2),
      blurRadius: elevation * 2,
      offset: Offset(0, elevation / 2),
      spreadRadius: 0,
    );
  }

  /// Create a glassmorphism border color
  static Color getGlassmorphismBorder({bool isDark = false}) {
    return Colors.white.withOpacity(isDark ? 0.15 : 0.25);
  }
}

/// Extension to add modern color utilities
extension ModernColorExtensions on Color {
  /// Create a lighter version of the color for glassmorphism
  Color get glassy => withOpacity(0.7);
  
  /// Create a muted version of the color
  Color get muted => Color.lerp(this, Colors.grey, 0.3) ?? this;
  
  /// Create a softer version by blending with white
  Color soft([double amount = 0.3]) => Color.lerp(this, Colors.white, amount) ?? this;
  
  /// Create a darker version by blending with black
  Color deep([double amount = 0.2]) => Color.lerp(this, Colors.black, amount) ?? this;
}
