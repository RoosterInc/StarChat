import 'package:flutter/material.dart';
import '../design_system/modern_ui_system.dart';

/// Simple responsive layout widget with mobile, tablet and desktop breakpoints.
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  /// Widget to display on mobile (<600px width).
  final WidgetBuilder mobile;

  /// Widget to display on tablet (>=600px and <1024px). Falls back to [mobile]
  /// when null.
  final WidgetBuilder? tablet;

  /// Widget to display on desktop (>=1024px). Falls back to [tablet] or [mobile]
  /// when null.
  final WidgetBuilder? desktop;

  /// Returns true when the current screen width is considered mobile.
  static bool isMobile(BuildContext context) => ResponsiveUtils.isMobile(context);

  /// Returns true when the current screen width is considered tablet.
  static bool isTablet(BuildContext context) => ResponsiveUtils.isTablet(context);

  /// Returns true when the current screen width is considered desktop.
  static bool isDesktop(BuildContext context) => ResponsiveUtils.isDesktop(context);

  @override
  Widget build(BuildContext context) {
    final width = context.screenWidth;
    if (width >= ResponsiveBreakpoints.desktop && desktop != null) {
      return desktop!(context);
    } else if (width >= ResponsiveBreakpoints.tablet && tablet != null) {
      return tablet!(context);
    } else {
      return mobile(context);
    }
  }
}
