import 'package:flutter/material.dart';

/// Responsive utilities for device-specific logic
/// Following AGENTS.md responsive design patterns
class ResponsiveUtils {
  // Breakpoints
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 1024.0;
  static const double desktopBreakpoint = 1440.0;

  /// Get device type based on screen width
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width < mobileBreakpoint) {
      return DeviceType.mobile;
    } else if (width < tabletBreakpoint) {
      return DeviceType.tablet;
    } else {
      return DeviceType.desktop;
    }
  }

  /// Check if device is mobile
  static bool isMobile(BuildContext context) =>
      getDeviceType(context) == DeviceType.mobile;

  /// Check if device is tablet
  static bool isTablet(BuildContext context) =>
      getDeviceType(context) == DeviceType.tablet;

  /// Check if device is desktop
  static bool isDesktop(BuildContext context) =>
      getDeviceType(context) == DeviceType.desktop;

  /// Return adaptive value based on device type
  static T adaptiveValue<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile;
    }
  }

  /// Get fluid size that scales between min and max based on screen width
  static double fluidSize(
    BuildContext context, {
    required double min,
    required double max,
  }) {
    final width = MediaQuery.of(context).size.width;
    final factor = (width - mobileBreakpoint) / 
                   (desktopBreakpoint - mobileBreakpoint);
    
    return min + (max - min) * factor.clamp(0.0, 1.0);
  }

  /// Get responsive columns for grid layouts
  static int getResponsiveColumns(BuildContext context) {
    return adaptiveValue(
      context,
      mobile: 1,
      tablet: 2,
      desktop: 3,
    );
  }

  /// Get responsive grid cross axis count
  static int getGridCrossAxisCount(BuildContext context) {
    return adaptiveValue(
      context,
      mobile: 2,
      tablet: 3,
      desktop: 4,
    );
  }

  /// Get responsive padding
  static EdgeInsets getResponsivePadding(BuildContext context) {
    final padding = adaptiveValue(
      context,
      mobile: 16.0,
      tablet: 24.0,
      desktop: 32.0,
    );
    
    return EdgeInsets.all(padding);
  }

  /// Get responsive margin
  static EdgeInsets getResponsiveMargin(BuildContext context) {
    final margin = adaptiveValue(
      context,
      mobile: 8.0,
      tablet: 12.0,
      desktop: 16.0,
    );
    
    return EdgeInsets.all(margin);
  }

  /// Get responsive font size
  static double getResponsiveFontSize(
    BuildContext context, {
    required double base,
  }) {
    final scale = adaptiveValue(
      context,
      mobile: 1.0,
      tablet: 1.1,
      desktop: 1.2,
    );
    
    return base * scale;
  }

  /// Check if device is in landscape mode
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  /// Check if device is in portrait mode
  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  /// Get safe area padding
  static EdgeInsets getSafeAreaPadding(BuildContext context) {
    return MediaQuery.of(context).padding;
  }

  /// Get view insets (e.g., keyboard height)
  static EdgeInsets getViewInsets(BuildContext context) {
    return MediaQuery.of(context).viewInsets;
  }

  /// Get screen size
  static Size getScreenSize(BuildContext context) {
    return MediaQuery.of(context).size;
  }

  /// Get responsive card width for grid items
  static double getCardWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = getResponsivePadding(context).horizontal;
    final columns = getGridCrossAxisCount(context);
    final spacing = 16.0 * (columns - 1);
    
    return (screenWidth - padding - spacing) / columns;
  }
}

/// Device type enumeration
enum DeviceType {
  mobile,
  tablet,
  desktop,
}