import 'package:flutter/material.dart';

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
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  /// Returns true when the current screen width is considered tablet.
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 &&
      MediaQuery.of(context).size.width < 1024;

  /// Returns true when the current screen width is considered desktop.
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1024;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1024 && desktop != null) {
      return desktop!(context);
    } else if (width >= 600 && tablet != null) {
      return tablet!(context);
    } else {
      return mobile(context);
    }
  }
}
