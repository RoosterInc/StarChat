import 'package:flutter/material.dart';

/// Design tokens for consistent spacing, colors, and sizing
/// Following AGENTS.md design system patterns
class DesignTokens {
  // Spacing values
  static const double _spaceXxs = 2.0;
  static const double _spaceXs = 4.0;
  static const double _spaceSm = 8.0;
  static const double _spaceMd = 16.0;
  static const double _spaceLg = 24.0;
  static const double _spaceXl = 32.0;
  static const double _spaceXxl = 48.0;

  // Icon sizes
  static const double _iconXs = 12.0;
  static const double _iconSm = 16.0;
  static const double _iconMd = 20.0;
  static const double _iconLg = 24.0;
  static const double _iconXl = 32.0;

  // Border radius
  static const double _radiusXs = 2.0;
  static const double _radiusSm = 4.0;
  static const double _radiusMd = 8.0;
  static const double _radiusLg = 12.0;
  static const double _radiusXl = 16.0;

  // Responsive spacing methods
  static EdgeInsets xxs(BuildContext context) => 
      const EdgeInsets.all(_spaceXxs);
  
  static EdgeInsets xs(BuildContext context) => 
      const EdgeInsets.all(_spaceXs);
  
  static EdgeInsets sm(BuildContext context) => 
      const EdgeInsets.all(_spaceSm);
  
  static EdgeInsets md(BuildContext context) => 
      const EdgeInsets.all(_spaceMd);
  
  static EdgeInsets lg(BuildContext context) => 
      const EdgeInsets.all(_spaceLg);
  
  static EdgeInsets xl(BuildContext context) => 
      const EdgeInsets.all(_spaceXl);
  
  static EdgeInsets xxl(BuildContext context) => 
      const EdgeInsets.all(_spaceXxl);

  // Icon sizes
  static double iconXs(BuildContext context) => _iconXs;
  static double iconSm(BuildContext context) => _iconSm;
  static double iconMd(BuildContext context) => _iconMd;
  static double iconLg(BuildContext context) => _iconLg;
  static double iconXl(BuildContext context) => _iconXl;

  // Border radius
  static double radiusXs(BuildContext context) => _radiusXs;
  static double radiusSm(BuildContext context) => _radiusSm;
  static double radiusMd(BuildContext context) => _radiusMd;
  static double radiusLg(BuildContext context) => _radiusLg;
  static double radiusXl(BuildContext context) => _radiusXl;
}

/// Extension for EdgeInsets to support directional padding
extension EdgeInsetsExtension on EdgeInsets {
  EdgeInsets get all => this;
  
  EdgeInsets symmetric({bool horizontal = false, bool vertical = false}) {
    if (horizontal && vertical) return this;
    if (horizontal) return EdgeInsets.symmetric(horizontal: left);
    if (vertical) return EdgeInsets.symmetric(vertical: top);
    return this;
  }

  double get width => left;
  double get height => top;
}