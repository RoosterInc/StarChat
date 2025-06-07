import 'package:flutter/material.dart';
import 'responsive_layout.dart';

/// Utility methods for calculating responsive sizes across the app.
class ResponsiveSizes {
  /// Calculates the width for horizontally scrolling list items such as
  /// chat rooms. The [availableWidth] should be the maximum width of the
  /// list. The item width adapts to the current breakpoint to keep a
  /// reasonable number of items visible on screen.
  static double chatRoomItemWidth(BuildContext context, double availableWidth) {
    // Number of items to fit in the available space for each breakpoint.
    const mobileCount = 3;
    const tabletCount = 4;
    const desktopCount = 5;

    final itemCount = ResponsiveLayout.isDesktop(context)
        ? desktopCount
        : ResponsiveLayout.isTablet(context)
            ? tabletCount
            : mobileCount;

    // Subtract spacing between items (8px) and divide the rest by the
    // number of items. Clamp the value to avoid excessively small or
    // large tiles on extreme sizes.
    const spacing = 8.0;
    final width = (availableWidth - spacing * (itemCount - 1)) / itemCount;
    return width.clamp(100.0, 200.0);
  }
}
