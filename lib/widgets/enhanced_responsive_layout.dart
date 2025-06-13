import 'package:flutter/material.dart';
import '../design_system/modern_ui_system.dart';

/// Enhanced responsive layout with orientation support and utilities.
class EnhancedResponsiveLayout extends StatelessWidget {
  const EnhancedResponsiveLayout({
    super.key,
    required this.mobile,
    this.mobileLandscape,
    this.tablet,
    this.tabletLandscape,
    this.desktop,
    this.desktopLandscape,
    this.breakpoints,
  });

  final WidgetBuilder mobile;
  final WidgetBuilder? mobileLandscape;
  final WidgetBuilder? tablet;
  final WidgetBuilder? tabletLandscape;
  final WidgetBuilder? desktop;
  final WidgetBuilder? desktopLandscape;
  final ResponsiveBreakpoints? breakpoints;

  @override
  Widget build(BuildContext context) {
    final screenSize = context.screenSize;
    final isLandscape = context.isLandscape;
    final bp = breakpoints ?? ResponsiveBreakpoints.defaultBreakpoints;

    if (screenSize.width >= bp.desktop) {
      if (isLandscape && desktopLandscape != null) {
        return desktopLandscape!(context);
      }
      return desktop?.call(context) ?? tablet?.call(context) ?? mobile(context);
    } else if (screenSize.width >= bp.tablet) {
      if (isLandscape && tabletLandscape != null) {
        return tabletLandscape!(context);
      }
      return tablet?.call(context) ?? mobile(context);
    } else {
      if (isLandscape && mobileLandscape != null) {
        return mobileLandscape!(context);
      }
      return mobile(context);
    }
  }

  static DeviceCategory getDeviceCategory(BuildContext context,
      [ResponsiveBreakpoints? breakpoints]) {
    final width = context.screenWidth;
    final bp = breakpoints ?? ResponsiveBreakpoints.defaultBreakpoints;
    if (width >= bp.desktop) return DeviceCategory.desktop;
    if (width >= bp.tablet) return DeviceCategory.tablet;
    return DeviceCategory.mobile;
  }

  static bool isMobile(BuildContext context,
          [ResponsiveBreakpoints? breakpoints]) =>
      getDeviceCategory(context, breakpoints) == DeviceCategory.mobile;
  static bool isTablet(BuildContext context,
          [ResponsiveBreakpoints? breakpoints]) =>
      getDeviceCategory(context, breakpoints) == DeviceCategory.tablet;
  static bool isDesktop(BuildContext context,
          [ResponsiveBreakpoints? breakpoints]) =>
      getDeviceCategory(context, breakpoints) == DeviceCategory.desktop;

  static bool isLandscape(BuildContext context) =>
      context.isLandscape;
  static bool isPortrait(BuildContext context) =>
      !context.isLandscape;
}

enum DeviceCategory { mobile, tablet, desktop }

class ResponsiveBreakpoints {
  const ResponsiveBreakpoints({required this.tablet, required this.desktop});

  final double tablet;
  final double desktop;

  static const defaultBreakpoints = ResponsiveBreakpoints(tablet: 600, desktop: 1024);
  static const compactBreakpoints = ResponsiveBreakpoints(tablet: 480, desktop: 840);
  static const extendedBreakpoints = ResponsiveBreakpoints(tablet: 768, desktop: 1200);
}

class ResponsiveUtils {
  static EdgeInsets getResponsivePadding(BuildContext context,
      {double mobile = 16.0, double tablet = 24.0, double desktop = 32.0}) {
    final category =
        EnhancedResponsiveLayout.getDeviceCategory(context);
    final value = switch (category) {
      DeviceCategory.mobile => mobile,
      DeviceCategory.tablet => tablet,
      DeviceCategory.desktop => desktop,
    };
    return EdgeInsets.all(value);
  }

  static double getResponsiveSpacing(BuildContext context,
      {double mobile = 16.0, double tablet = 24.0, double desktop = 32.0}) {
    final category =
        EnhancedResponsiveLayout.getDeviceCategory(context);
    return switch (category) {
      DeviceCategory.mobile => mobile,
      DeviceCategory.tablet => tablet,
      DeviceCategory.desktop => desktop,
    };
  }

  static double getResponsiveFontSize(BuildContext context, double baseSize,
      {double mobileScale = 1.0,
      double tabletScale = 1.1,
      double desktopScale = 1.2}) {
    final category =
        EnhancedResponsiveLayout.getDeviceCategory(context);
    final scale = switch (category) {
      DeviceCategory.mobile => mobileScale,
      DeviceCategory.tablet => tabletScale,
      DeviceCategory.desktop => desktopScale,
    };
    return baseSize * scale;
  }
}
