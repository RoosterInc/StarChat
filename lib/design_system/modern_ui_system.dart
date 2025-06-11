// ============================================================================
// FLUTTER UI/UX MODERNIZATION SYSTEM 2024-2025
// Complete implementation with Material Design 3, Responsive Design,
// Micro-interactions, Glassmorphism, and Performance Optimizations
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:math' as math;

// ============================================================================
// DESIGN TOKENS - Foundation of the Design System
// ============================================================================

class DesignTokens {
  // SPACING SYSTEM - Fluid spacing that adapts to screen size
  static double spacing(BuildContext context, double baseValue) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = screenWidth < 600 ? 1.0 : 
                       screenWidth < 1024 ? 1.2 : 1.4;
    return baseValue * scaleFactor;
  }

  // Pre-defined spacing values
  static double xs(BuildContext context) => spacing(context, 4);
  static double sm(BuildContext context) => spacing(context, 8);
  static double md(BuildContext context) => spacing(context, 16);
  static double lg(BuildContext context) => spacing(context, 24);
  static double xl(BuildContext context) => spacing(context, 32);
  static double xxl(BuildContext context) => spacing(context, 48);

  // BORDER RADIUS SYSTEM
  static double radiusXs(BuildContext context) => spacing(context, 4);
  static double radiusSm(BuildContext context) => spacing(context, 8);
  static double radiusMd(BuildContext context) => spacing(context, 12);
  static double radiusLg(BuildContext context) => spacing(context, 16);
  static double radiusXl(BuildContext context) => spacing(context, 24);

  // ELEVATION SYSTEM
  static const List<BoxShadow> elevation1 = [
    BoxShadow(color: Color(0x0D000000), blurRadius: 1, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x1A000000), blurRadius: 2, offset: Offset(0, 1)),
  ];
  
  static const List<BoxShadow> elevation2 = [
    BoxShadow(color: Color(0x1A000000), blurRadius: 2, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 2)),
  ];
  
  static const List<BoxShadow> elevation3 = [
    BoxShadow(color: Color(0x1A000000), blurRadius: 4, offset: Offset(0, 2)),
    BoxShadow(color: Color(0x1A000000), blurRadius: 12, offset: Offset(0, 4)),
  ];

  // ANIMATION CURVES & DURATIONS
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationNormal = Duration(milliseconds: 300);
  static const Duration durationSlow = Duration(milliseconds: 500);
  
  static const Curve curveEaseOut = Curves.easeOut;
  static const Curve curveEaseInOut = Curves.easeInOut;
  static const Curve curveSpring = Curves.elasticOut;
}

// ============================================================================
// RESPONSIVE BREAKPOINTS & UTILITIES
// ============================================================================

enum DeviceType { mobile, tablet, desktop }
enum Orientation { portrait, landscape }

class ResponsiveBreakpoints {
  static const double mobile = 600;
  static const double tablet = 1024;
  static const double desktop = 1440;
}

class ResponsiveUtils {
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < ResponsiveBreakpoints.mobile) return DeviceType.mobile;
    if (width < ResponsiveBreakpoints.tablet) return DeviceType.tablet;
    return DeviceType.desktop;
  }

  static bool isMobile(BuildContext context) => 
      getDeviceType(context) == DeviceType.mobile;
  
  static bool isTablet(BuildContext context) => 
      getDeviceType(context) == DeviceType.tablet;
  
  static bool isDesktop(BuildContext context) => 
      getDeviceType(context) == DeviceType.desktop;

  static bool isLandscape(BuildContext context) =>
      MediaQuery.of(context).orientation == Orientation.landscape;

  // Adaptive values based on device type
  static T adaptiveValue<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    switch (getDeviceType(context)) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile;
    }
  }

  // Fluid sizing that adapts to screen width
  static double fluidSize(
    BuildContext context, {
    required double min,
    required double max,
    double? ideal,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final normalizedWidth = (screenWidth - ResponsiveBreakpoints.mobile) / 
                           (ResponsiveBreakpoints.desktop - ResponsiveBreakpoints.mobile);
    final clampedWidth = normalizedWidth.clamp(0.0, 1.0);
    return min + (max - min) * clampedWidth;
  }
}

// ============================================================================
// ADVANCED MATERIAL DESIGN 3 THEME SYSTEM
// ============================================================================

class MD3ThemeSystem {
  // Generate dynamic color scheme from seed color
  static ColorScheme generateColorScheme({
    required Color seedColor,
    required Brightness brightness,
  }) {
    return ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );
  }

  // Create complete theme with MD3 enhancements
  static ThemeData createTheme({
    required Color seedColor,
    required Brightness brightness,
  }) {
    final colorScheme = generateColorScheme(
      seedColor: seedColor,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      
      // Enhanced Typography with fluid scaling
      textTheme: _createTextTheme(colorScheme),
      
      // Modern component themes
      appBarTheme: _createAppBarTheme(colorScheme),
      navigationBarTheme: _createNavigationBarTheme(colorScheme),
      cardTheme: _createCardTheme(colorScheme),
      elevatedButtonTheme: _createElevatedButtonTheme(colorScheme),
      filledButtonTheme: _createFilledButtonTheme(colorScheme),
      inputDecorationTheme: _createInputDecorationTheme(colorScheme),
      
      // Enhanced visual density for better touch targets
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }

  static TextTheme _createTextTheme(ColorScheme colorScheme) {
    return TextTheme(
      // Display styles
      displayLarge: TextStyle(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.25,
        color: colorScheme.onSurface,
        height: 1.12,
      ),
      displayMedium: TextStyle(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: colorScheme.onSurface,
        height: 1.16,
      ),
      displaySmall: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: colorScheme.onSurface,
        height: 1.22,
      ),
      
      // Headline styles
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: colorScheme.onSurface,
        height: 1.25,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: colorScheme.onSurface,
        height: 1.29,
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: colorScheme.onSurface,
        height: 1.33,
      ),
      
      // Title styles
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: colorScheme.onSurface,
        height: 1.27,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        color: colorScheme.onSurface,
        height: 1.5,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: colorScheme.onSurface,
        height: 1.43,
      ),
      
      // Body styles
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        color: colorScheme.onSurface,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        color: colorScheme.onSurface,
        height: 1.43,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        color: colorScheme.onSurfaceVariant,
        height: 1.33,
      ),
      
      // Label styles
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: colorScheme.onSurface,
        height: 1.43,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: colorScheme.onSurface,
        height: 1.33,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: colorScheme.onSurface,
        height: 1.45,
      ),
    );
  }

  static AppBarTheme _createAppBarTheme(ColorScheme colorScheme) {
    return AppBarTheme(
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: colorScheme.shadow,
      surfaceTintColor: colorScheme.surfaceTint,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
    );
  }

  static NavigationBarThemeData _createNavigationBarTheme(
      ColorScheme colorScheme) {
    return NavigationBarThemeData(
      backgroundColor: colorScheme.surface,
      indicatorColor: colorScheme.secondaryContainer,
      elevation: 3,
      shadowColor: colorScheme.shadow,
      surfaceTintColor: colorScheme.surfaceTint,
      labelTextStyle: MaterialStateProperty.resolveWith<TextStyle?>((states) {
        if (states.contains(MaterialState.selected)) {
          return TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          );
        }
        return TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurfaceVariant,
        );
      }),
    );
  }

  static CardTheme _createCardTheme(ColorScheme colorScheme) {
    return CardTheme(
      color: colorScheme.surface,
      surfaceTintColor: colorScheme.surfaceTint,
      elevation: 1,
      shadowColor: colorScheme.shadow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  static ElevatedButtonThemeData _createElevatedButtonTheme(ColorScheme colorScheme) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.primary,
        elevation: 1,
        shadowColor: colorScheme.shadow,
        surfaceTintColor: colorScheme.surfaceTint,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),
    );
  }

  static FilledButtonThemeData _createFilledButtonTheme(ColorScheme colorScheme) {
    return FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),
    );
  }

  static InputDecorationTheme _createInputDecorationTheme(ColorScheme colorScheme) {
    return InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceVariant.withOpacity(0.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
      hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withOpacity(0.6)),
    );
  }
}

// ============================================================================
// MICRO-INTERACTIONS & ANIMATION SYSTEM
// ============================================================================

class MicroInteractions {
  // Haptic feedback patterns
  static void lightHaptic() => HapticFeedback.lightImpact();
  static void mediumHaptic() => HapticFeedback.mediumImpact();
  static void heavyHaptic() => HapticFeedback.heavyImpact();
  static void selectionHaptic() => HapticFeedback.selectionClick();
}

// Enhanced button with micro-interactions
class AnimatedButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final ButtonStyle? style;
  final bool enableHaptics;
  final Duration animationDuration;

  const AnimatedButton({
    Key? key,
    required this.child,
    this.onPressed,
    this.style,
    this.enableHaptics = true,
    this.animationDuration = const Duration(milliseconds: 150),
  }) : super(key: key);

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null) {
      _controller.forward();
      if (widget.enableHaptics) {
        MicroInteractions.lightHaptic();
      }
    }
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: FilledButton(
              onPressed: null, // Handled by GestureDetector
              style: widget.style,
              child: widget.child,
            ),
          );
        },
      ),
    );
  }
}

// Staggered animation for lists
class StaggeredListView extends StatelessWidget {
  final List<Widget> children;
  final Duration staggerDelay;
  final Duration animationDuration;
  final Axis scrollDirection;

  const StaggeredListView({
    Key? key,
    required this.children,
    this.staggerDelay = const Duration(milliseconds: 100),
    this.animationDuration = const Duration(milliseconds: 500),
    this.scrollDirection = Axis.vertical,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      scrollDirection: scrollDirection,
      itemCount: children.length,
      itemBuilder: (context, index) {
        return StaggeredListItem(
          index: index,
          staggerDelay: staggerDelay,
          animationDuration: animationDuration,
          child: children[index],
        );
      },
    );
  }
}

class StaggeredListItem extends StatefulWidget {
  final int index;
  final Duration staggerDelay;
  final Duration animationDuration;
  final Widget child;

  const StaggeredListItem({
    Key? key,
    required this.index,
    required this.staggerDelay,
    required this.animationDuration,
    required this.child,
  }) : super(key: key);

  @override
  State<StaggeredListItem> createState() => _StaggeredListItemState();
}

class _StaggeredListItemState extends State<StaggeredListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 1.0, curve: Curves.easeOutCubic),
    ));

    // Start animation with stagger delay
    Future.delayed(
      Duration(milliseconds: widget.index * widget.staggerDelay.inMilliseconds),
      () {
        if (mounted) {
          _controller.forward();
        }
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: widget.child,
          ),
        );
      },
    );
  }
}

// ============================================================================
// GLASSMORPHISM COMPONENTS
// ============================================================================

class GlassmorphicContainer extends StatelessWidget {
  final Widget? child;
  final double width;
  final double height;
  final double blur;
  final double opacity;
  final Color? color;
  final BorderRadius? borderRadius;
  final Border? border;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const GlassmorphicContainer({
    Key? key,
    this.child,
    this.width = double.infinity,
    this.height = double.infinity,
    this.blur = 10.0,
    this.opacity = 0.1,
    this.color,
    this.borderRadius,
    this.border,
    this.padding,
    this.margin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      width: width,
      height: height,
      margin: margin,
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: color ?? 
                     (isDark 
                      ? Colors.white.withOpacity(opacity) 
                      : Colors.white.withOpacity(opacity * 2)),
              borderRadius: borderRadius ?? BorderRadius.circular(12),
              border: border ?? 
                     Border.all(
                       color: Colors.white.withOpacity(isDark ? 0.1 : 0.2),
                       width: 1,
                     ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class GlassmorphicCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  const GlassmorphicCard({
    Key? key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassmorphicContainer(
        padding: padding ?? DesignTokens.md(context).all,
        margin: margin,
        blur: 15,
        opacity: 0.15,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd(context)),
        child: child,
      ),
    );
  }
}

// ============================================================================
// ENHANCED NAVIGATION SYSTEM
// ============================================================================

class AdaptiveNavigation extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onDestinationSelected;
  final List<NavigationDestination> destinations;
  final Widget body;
  final Widget? drawer;

  const AdaptiveNavigation({
    Key? key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    required this.body,
    this.drawer,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (ResponsiveUtils.isDesktop(context)) {
      return _buildDesktopLayout(context);
    } else if (ResponsiveUtils.isTablet(context)) {
      return _buildTabletLayout(context);
    } else {
      return _buildMobileLayout(context);
    }
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      body: body,
      drawer: drawer,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: destinations,
        animationDuration: DesignTokens.durationNormal,
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            extended: true,
            destinations: destinations
                .map((dest) => NavigationRailDestination(
                      icon: dest.icon,
                      selectedIcon: dest.selectedIcon,
                      label: Text(dest.label),
                    ))
                .toList(),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: body),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 280,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                right: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: DesignTokens.lg(context).all,
                  child: Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 32,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      SizedBox(width: DesignTokens.md(context)),
                      Text(
                        'StarChat',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    itemCount: destinations.length,
                    itemBuilder: (context, index) {
                      final dest = destinations[index];
                      final isSelected = index == selectedIndex;
                      return Container(
                        margin: EdgeInsets.symmetric(
                          horizontal: DesignTokens.sm(context),
                          vertical: DesignTokens.xs(context),
                        ),
                        child: ListTile(
                          leading: isSelected ? dest.selectedIcon : dest.icon,
                          title: Text(dest.label),
                          selected: isSelected,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              DesignTokens.radiusMd(context),
                            ),
                          ),
                          onTap: () => onDestinationSelected(index),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}

// ============================================================================
// PERFORMANCE-OPTIMIZED COMPONENTS
// ============================================================================

class OptimizedListView extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;
  final double? itemExtent;

  const OptimizedListView({
    Key? key,
    required this.itemCount,
    required this.itemBuilder,
    this.controller,
    this.padding,
    this.itemExtent,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      padding: padding,
      itemCount: itemCount,
      itemBuilder: itemBuilder,
      itemExtent: itemExtent,
      // Performance optimizations
      cacheExtent: 500,
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: true,
      addSemanticIndexes: true,
    );
  }
}

// Skeleton loading component
class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const SkeletonLoader({
    Key? key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius,
  }) : super(key: key);

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    
    _animation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(4),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                isDark 
                  ? Colors.grey[800]! 
                  : Colors.grey[300]!,
                isDark 
                  ? Colors.grey[700]! 
                  : Colors.grey[100]!,
                isDark 
                  ? Colors.grey[800]! 
                  : Colors.grey[300]!,
              ],
              stops: [
                math.max(0.0, _animation.value - 0.3),
                _animation.value,
                math.min(1.0, _animation.value + 0.3),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ============================================================================
// ACCESSIBILITY ENHANCEMENTS
// ============================================================================

class AccessibilityWrapper extends StatelessWidget {
  final Widget child;
  final String? semanticLabel;
  final String? hint;
  final bool isButton;
  final VoidCallback? onTap;

  const AccessibilityWrapper({
    Key? key,
    required this.child,
    this.semanticLabel,
    this.hint,
    this.isButton = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      hint: hint,
      button: isButton,
      onTap: onTap,
      child: child,
    );
  }
}

// ============================================================================
// UTILITY EXTENSIONS
// ============================================================================

extension ContextExtensions on BuildContext {
  // Theme shortcuts
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => theme.colorScheme;
  TextTheme get textTheme => theme.textTheme;
  
  // Responsive shortcuts
  bool get isMobile => ResponsiveUtils.isMobile(this);
  bool get isTablet => ResponsiveUtils.isTablet(this);
  bool get isDesktop => ResponsiveUtils.isDesktop(this);
  bool get isLandscape => ResponsiveUtils.isLandscape(this);
  
  // Screen dimensions
  Size get screenSize => MediaQuery.of(this).size;
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;
}

extension PaddingExtensions on double {
  EdgeInsets get all => EdgeInsets.all(this);
  EdgeInsets get horizontal => EdgeInsets.symmetric(horizontal: this);
  EdgeInsets get vertical => EdgeInsets.symmetric(vertical: this);
  EdgeInsets get left => EdgeInsets.only(left: this);
  EdgeInsets get right => EdgeInsets.only(right: this);
  EdgeInsets get top => EdgeInsets.only(top: this);
  EdgeInsets get bottom => EdgeInsets.only(bottom: this);
}

// ============================================================================
// EXAMPLE USAGE DEMONSTRATION
// ============================================================================

class ModernUIDemo extends StatefulWidget {
  const ModernUIDemo({Key? key}) : super(key: key);

  @override
  State<ModernUIDemo> createState() => _ModernUIDemoState();
}

class _ModernUIDemoState extends State<ModernUIDemo> {
  int _selectedIndex = 0;
  bool _isLoading = false;

  final List<NavigationDestination> _destinations = [
    const NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: 'Home',
    ),
    const NavigationDestination(
      icon: Icon(Icons.search_outlined),
      selectedIcon: Icon(Icons.search),
      label: 'Search',
    ),
    const NavigationDestination(
      icon: Icon(Icons.favorite_outline),
      selectedIcon: Icon(Icons.favorite),
      label: 'Favorites',
    ),
    const NavigationDestination(
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person),
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Modern UI Demo',
      theme: MD3ThemeSystem.createTheme(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      ),
      darkTheme: MD3ThemeSystem.createTheme(
        seedColor: Colors.blue,
        brightness: Brightness.dark,
      ),
      home: AdaptiveNavigation(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: _destinations,
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modern UI Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: () {
              // Toggle theme (implementation depends on your state management)
            },
          ),
        ],
      ),
      body: Padding(
        padding: DesignTokens.md(context).all,
        child: _isLoading ? _buildLoadingState() : _buildContent(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        SkeletonLoader(
          height: 200,
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd(context)),
        ),
        SizedBox(height: DesignTokens.md(context)),
        ...List.generate(
          5,
          (index) => Padding(
            padding: DesignTokens.sm(context).bottom,
            child: SkeletonLoader(
              height: 60,
              borderRadius: BorderRadius.circular(DesignTokens.radiusSm(context)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return StaggeredListView(
      children: [
        // Glassmorphic hero card
        GlassmorphicCard(
          child: Container(
            height: ResponsiveUtils.fluidSize(
              context,
              min: 150,
              max: 200,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: ResponsiveUtils.fluidSize(context, min: 40, max: 60),
                  color: context.colorScheme.primary,
                ),
                SizedBox(height: DesignTokens.md(context)),
                Text(
                  'Modern UI System',
                  style: context.textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: DesignTokens.sm(context)),
                Text(
                  'Built with Material Design 3',
                  style: context.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        
        SizedBox(height: DesignTokens.lg(context)),
        
        // Interactive buttons
        Row(
          children: [
            Expanded(
              child: AnimatedButton(
                onPressed: () {
                  setState(() => _isLoading = true);
                  Future.delayed(const Duration(seconds: 2), () {
                    if (mounted) {
                      setState(() => _isLoading = false);
                    }
                  });
                },
                child: const Text('Load Data'),
              ),
            ),
            SizedBox(width: DesignTokens.md(context)),
            Expanded(
              child: AnimatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Action completed!'),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(DesignTokens.radiusSm(context)),
                      ),
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: context.colorScheme.secondary,
                ),
                child: const Text('Secondary'),
              ),
            ),
          ],
        ),
        
        SizedBox(height: DesignTokens.lg(context)),
        
        // List items with cards
        ...List.generate(
          10,
          (index) => Card(
            margin: DesignTokens.sm(context).bottom,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: context.colorScheme.primaryContainer,
                child: Text('${index + 1}'),
              ),
              title: Text('Item ${index + 1}'),
              subtitle: Text('Subtitle for item ${index + 1}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                MicroInteractions.selectionHaptic();
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// MAIN DEMO APP
// ============================================================================

void main() {
  runApp(const ModernUIDemo());
}
