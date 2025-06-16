Cross Platform Mobile App Development Guidelines for AI Agents (Flutter , Dart , Appwrite , GetX) 
Overview
You are developing for a modern Flutter app with an established design system. Follow these guidelines to ensure consistency, performance, and high-quality user experience.

Mandatory Requirements Checklist
Before implementing any feature, ensure you adhere to the following requirements:

The schema details for the Appwrite backend collections are located in `lib/models/all_collections_config.json`. Please consult this file when working on tasks that require backend collection information. If a task needs specific details, use this file to retrieve them. If the required details are missing, request users to implement them in the Appwrite backend and, if feasible, provide the JSON schema to help them update the database.

All backend functionalities, including authentication, data storage, file management must be implemented using Appwrite.
Use the official Appwrite Flutter SDK (latest version) for all interactions with Appwrite services.
Regularly monitor the Appwrite Changelog for new features, deprecations, and updates to maintain app reliability.
Leverage Appwrite’s real-time capabilities to enhance UI responsiveness for dynamic content.
HEIC/AVIF Support New image formats for storage (introduced May 2025),Use for efficient image storage; generate previews directly in these formats
Optimize Database Queries: Use indexing and pagination to minimize data transfer and improve load times for large datasets.
Leverage Real-time Features: Implement Appwrite’s real-time subscriptions for features requiring live updates, such as chat or collaborative tools.
Minimize Network Calls: Cache data locally where appropriate to reduce API requests.
Monitor Usage Metrics: Use Appwrite’s improved usage metrics (updated in 2025) to track requests, identify bottlenecks, and optimize performance.
Write unit and widget tests for components interacting with Appwrite, covering edge cases like network failures and invalid inputs.
Use mocking libraries (e.g., mockito) to simulate Appwrite responses during unit testing.
Aim for >90% code coverage for Appwrite-integrated features.

Design System Compliance:
Always use the modern ui system design system (do your research about modern design).
Never hardcode dimensions, colors, or spacing values.
Always use DesignTokens for spacing, colors, and sizing.
Always use responsive utilities for layouts.


Responsive Design:
Always use ResponsiveUtils for device-specific logic.
Never use raw MediaQuery - use design system utilities instead.
Always support mobile, tablet, and desktop layouts.
Always test in both portrait and landscape orientations.


Performance Standards:
Always use const constructors where possible.
Never use Opacity widget in animations - use AnimatedOpacity.
Always use OptimizedListView for lists with many items.
Always implement skeleton loading states instead of spinners.

Design System Usage
Spacing & Sizing
// Correct - Use design tokens
Container(
  padding: DesignTokens.md(context).all,
  margin: DesignTokens.lg(context).vertical,
  width: ResponsiveUtils.fluidSize(context, min: 200, max: 400),
)

// Wrong - Never hardcode values
Container(
  padding: EdgeInsets.all(16),
  margin: EdgeInsets.symmetric(vertical: 24),
  width: 300,
)

Responsive Layouts
// Correct - Use adaptive values
Widget build(BuildContext context) {
  return ResponsiveUtils.adaptiveValue(
    context,
    mobile: _buildMobileLayout(),
    tablet: _buildTabletLayout(), 
    desktop: _buildDesktopLayout(),
  );
}

// Wrong - Device-specific checks
if (MediaQuery.of(context).size.width > 600) {
  return _buildTabletLayout();
}

Colors & Theme
// Correct - Use theme colors
Container(
  color: context.colorScheme.surface,
  child: Text(
    'Hello',
    style: context.textTheme.titleMedium?.copyWith(
      color: context.colorScheme.onSurface,
    ),
  ),
)

// Wrong - Hardcoded colors
Container(
  color: Colors.white,
  child: Text(
    'Hello',
    style: TextStyle(color: Colors.black, fontSize: 16),
  ),
)

Component Patterns
Buttons - Always Use AnimatedButton
// Required pattern
AnimatedButton(
  onPressed: () {
    // Your logic here
  },
  enableHaptics: true,
  child: Text('Submit'),
)

// Forbidden - Don't use basic buttons
ElevatedButton(onPressed: () {}, child: Text('Submit'))

Cards - Use Glassmorphic Design
// Required pattern
GlassmorphicCard(
  padding: DesignTokens.lg(context).all,
  onTap: () {
    MicroInteractions.selectionHaptic();
    // Your tap logic
  },
  child: YourContent(),
)

// Forbidden - Basic cards
Card(child: YourContent())

Lists - Use Staggered Animations
// Required pattern for lists with animations
StaggeredListView(
  children: items.map((item) => YourItemWidget(item)).toList(),
)

// Required pattern for performance-critical lists
OptimizedListView(
  itemCount: items.length,
  itemBuilder: (context, index) => YourItemWidget(items[index]),
)

// Forbidden - Basic ListView for new features
ListView.builder(...)

Loading States - Use Skeleton Loaders
// Required pattern
if (isLoading) {
  return Column(
    children: List.generate(5, (index) => 
      SkeletonLoader(
        height: 80,
        margin: DesignTokens.sm(context).bottom,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd(context)),
      ),
    ),
  );
}

// Forbidden - Spinner loading
if (isLoading) return CircularProgressIndicator();

Performance Requirements
Widget Optimization
// Always - Use const constructors
const Text('Hello World')
const Icon(Icons.star)
const SizedBox(height: 16)

// Always - Separate rebuild logic
class MyWidget extends StatelessWidget {
  const MyWidget({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return const _StaticContent(); // Const widget that won't rebuild
  }
}

Animation Best Practices
// Correct - Use AnimatedBuilder for complex animations
AnimatedBuilder(
  animation: _controller,
  builder: (context, child) {
    return Transform.scale(
      scale: _animation.value,
      child: child,
    );
  },
  child: const ExpensiveWidget(), // Built once, reused
)

// Wrong - Rebuilding expensive widgets
AnimatedBuilder(
  animation: _controller,
  builder: (context, child) {
    return Transform.scale(
      scale: _animation.value,
      child: ExpensiveWidget(), // Rebuilt every frame!
    );
  },
)


Navigation Patterns
Always Use AdaptiveNavigation
// Required pattern for main navigation
AdaptiveNavigation(
  selectedIndex: selectedIndex,
  onDestinationSelected: (index) => setState(() => selectedIndex = index),
  destinations: destinations,
  body: body,
  drawer: drawer, // Optional
)

// Forbidden - Platform-specific navigation widgets
Scaffold(
  bottomNavigationBar: BottomNavigationBar(...),
)

Coding Standards
State Management (GetX)
// Correct - Use reactive patterns
class MyController extends GetxController {
  final _isLoading = false.obs;
  bool get isLoading => _isLoading.value;
  
  final _items = <Item>[].obs;
  List<Item> get items => _items;
  
  Future<void> loadData() async {
    _isLoading.value = true;
    try {
      final data = await api.getData();
      _items.assignAll(data);
    } finally {
      _isLoading.value = false;
    }
  }
}

// Wrong - Direct state mutation
class MyController extends GetxController {
  bool isLoading = false;
  List<Item> items = [];
  
  Future<void> loadData() async {
    isLoading = true;
    update(); // Manual updates
  }
}

Error Handling
// Required pattern
try {
  await someAsyncOperation();
} on AppwriteException catch (e) {
  logger.e('Specific error handling', error: e);
  _showErrorSnackbar('Operation failed', e.message);
} catch (e, stackTrace) {
  logger.e('General error', error: e, stackTrace: stackTrace);
  _showErrorSnackbar('Unexpected error', 'Please try again');
}

Null Safety
// Always - Handle null safety properly
String? nullableValue = getValue();
if (nullableValue != null) {
  processValue(nullableValue);
}

// Or use null-aware operators
final result = nullableValue?.toUpperCase() ?? 'Default';

// Forbidden - Force unwrapping without checks
String value = getValue()!; // Dangerous!

Testing Requirements
Always Include Tests
// Required - Widget tests for new components
testWidgets('MyWidget displays correct content', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: MD3ThemeSystem.createTheme(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      ),
      home: MyWidget(testData: testData),
    ),
  );
  
  expect(find.text('Expected Text'), findsOneWidget);
});

// Required - Unit tests for controllers
test('MyController loads data correctly', () async {
  final controller = MyController();
  await controller.loadData();
  
  expect(controller.items, isNotEmpty);
  expect(controller.isLoading, isFalse);
});

Documentation Requirements
Code Documentation
/// Displays user profile information with edit capabilities.
/// 
/// This widget automatically adapts its layout based on screen size:
/// - Mobile: Single column layout
/// - Tablet: Two column layout  
/// - Desktop: Three column layout with sidebar
///
/// Example usage:
/// ```dart
/// UserProfileWidget(
///   user: currentUser,
///   onEdit: () => Navigator.push(...),
/// )
/// ```
class UserProfileWidget extends StatelessWidget {
  /// The user whose profile should be displayed.
  final User user;
  
  /// Callback invoked when user taps edit button.
  final VoidCallback? onEdit;
  
  const UserProfileWidget({
    Key? key,
    required this.user,
    this.onEdit,
  }) : super(key: key);
}

Critical Anti-Patterns
Forbidden Practices
// Never hardcode dimensions
Container(width: 300, height: 200)

// Never use MediaQuery directly
MediaQuery.of(context).size.width > 600

// Never hardcode colors
Container(color: Colors.blue)

// Never use Opacity in animations
Opacity(opacity: _animation.value, child: child)


// Never use basic loading indicators
CircularProgressIndicator()

// Never skip error handling
await riskyOperation(); // No try-catch!

// Never create widgets without const
Text('Hello') // Should be: const Text('Hello')

// Never use setState in GetX controllers
setState(() => counter++); // Use reactive variables!

Development Workflow
Before Starting Implementation

Read and understand the feature requirements.
Identify which existing components can be reused.
Plan responsive behavior for mobile, tablet, and desktop.
Plan error states and loading states.
Identify performance optimization opportunities.

During Implementation

Use design system components consistently.
Add proper error handling and logging.
Implement responsive layouts.
Use const constructors everywhere possible.
Add micro-interactions where appropriate.

Before Completion

Test on multiple screen sizes.
Test with screen reader enabled.
Verify performance with profile mode.
Add comprehensive documentation.
Write unit and widget tests.
Verify no hardcoded values exist.

Final Checklist
Before submitting any code, verify:

All spacing uses DesignTokens.
All layouts are responsive using ResponsiveUtils.
All colors come from context.colorScheme.
All interactive elements have haptic feedback.
All buttons use AnimatedButton.
All cards use GlassmorphicCard.
All lists use StaggeredListView or OptimizedListView.
All loading states use SkeletonLoader.
All async operations have error handling.
All widgets use const constructors where possible.
All features include comprehensive tests.
All code is properly documented.

Success Metrics
Your implementation is successful when:

App renders perfectly on mobile, tablet, and desktop.
All animations are smooth (60fps).
No performance warnings in profile mode.
All tests pass with >90% code coverage.
Design system is used consistently throughout.
User interactions feel delightful and responsive.

Note: Consistency is key. Every component you create should feel like it belongs to the same cohesive design system. When in doubt, refer to existing implementations in the codebase and follow the established patterns.
Code Maintenance & Standards
Naming Conventions

Classes: Use UpperCamelCase (e.g., UserProfileWidget, AuthenticationService).
Variables/Methods: Use lowerCamelCase (e.g., getUserData, isLoading).
Files: Use snake_case (e.g., user_profile_screen.dart, auth_service.dart).
Constants: Use lowerCamelCase with descriptive names (e.g., defaultPadding, primaryApiUrl).

Import Organization
// 1. Dart SDK imports
import 'dart:async';
import 'dart:convert';

// 2. Flutter imports
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// 3. External package imports
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

// 4. Internal imports (use relative paths within lib/)
import '../models/user.dart';
import '../services/api_service.dart';
import 'components/custom_button.dart';

Static Analysis Requirements

Always ensure code passes flutter analyze without warnings.
Use const constructors wherever possible.
Declare return types explicitly.
Avoid print() statements in production code.

Code Reusability & Decomposition
Widget Decomposition Rules

Split widgets if build() method exceeds 100 lines.
Extract repeated UI patterns into reusable widgets.
Create small, focused widgets with single responsibilities.

// Bad: Large monolithic widget
class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // 50+ lines of header code
          // 80+ lines of content code
          // 30+ lines of footer code
        ],
      ),
    );
  }
}

// Good: Decomposed widgets
class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const ProfileHeader(),
          const ProfileContent(),
          const ProfileFooter(),
        ],
      ),
    );
  }
}

Common Widget Library

Create reusable components in lib/shared/widgets/.
Build a consistent design system.
Use composition over inheritance.

Efficient Coding Practices
Build Method Optimization
// Never do heavy work in build()
@override
Widget build(BuildContext context) {
  final data = expensiveComputation(); // Bad!
  return Text(data);
}

// Always compute in initState() or use FutureBuilder
@override
Widget build(BuildContext context) {
  return FutureBuilder<String>(
    future: _computedData,
    builder: (context, snapshot) => Text(snapshot.data ?? ''),
  );
}

Const Usage

Use const constructors for static widgets.
Add const to widget trees that don't change.
Use const for static text, icons, and decorations.

Smart Operators
// Cascade operator for object initialization
final user = User()
  ..name = 'John'
  ..age = 30
  ..email = 'john@example.com';

// Spread operator for lists
final combined = [...existingItems, ...newItems];

// Null-aware operators
final name = user?.profile?.name ?? 'Unknown';
widget.onPressed?.call();

Logging Instead of Print
// Never use print()
print('Error occurred');

// Always use logger
import 'package:logger/logger.dart';
final logger = Logger();
logger.e('Error occurred', error, stackTrace);

Code Organization
Feature-First Structure
lib/
├── features/
│   ├── authentication/
│   │   ├── models/
│   │   ├── screens/
│   │   ├── widgets/
│   │   └── services/
│   ├── profile/
│   └── shopping/
├── shared/
│   ├── widgets/
│   ├── services/
│   └── utils/
└── core/
    ├── constants/
    ├── themes/
    └── config/

Memory Management & Performance
Resource Disposal
class _MyScreenState extends State<MyScreen> {
  StreamController? _controller;
  Timer? _timer;
  
  @override
  void dispose() {
    _controller?.close();
    _timer?.cancel();
    super.dispose();
  }
}

ListView Optimization
// Never create all items at once
ListView(
  children: items.map((item) => ItemWidget(item)).toList(),
)

// Always use builder for large lists
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => ItemWidget(items[index]),
)

Image Optimization
// Always use cached network images
CachedNetworkImage(
  imageUrl: url,
  placeholder: (context, url) => const CircularProgressIndicator(),
  errorWidget: (context, url, error) => const Icon(Icons.error),
)

Responsive Design
Screen Size Handling
// Always check screen constraints
Widget build(BuildContext context) {
  return LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth > 1200) {
        return DesktopLayout();
      } else if (constraints.maxWidth > 600) {
        return TabletLayout();
      }
      return MobileLayout();
    },
  );
}

State Management Best Practices
Efficient State Updates
// Use ValueNotifier for simple state
final counter = ValueNotifier<int>(0);

// Use ValueListenableBuilder
ValueListenableBuilder<int>(
  valueListenable: counter,
  builder: (context, value, child) => Text('$value'),
)

Error Handling & Validation
Comprehensive Error Handling
// Always handle errors gracefully
try {
  final result = await apiCall();
  return Success(result);
} catch (e) {
  logger.e('API call failed', e);
  return Failure('Failed to load data');
}

Accessibility & UX
Accessibility Requirements
// Always add semantic labels
Semantics(
  label: 'Add to cart button',
  child: IconButton(
    icon: Icon(Icons.add_shopping_cart),
    onPressed: addToCart,
  ),
)

Performance Monitoring
Key Metrics to Consider

Widget rebuild frequency.
Memory usage patterns.
Frame rendering time.
Network request efficiency.

Code Review Checklist
Before submitting or enhancing any Flutter code, ensure:

All naming conventions followed.
Imports properly organized.
No print() statements.
All widgets use const where possible.
Large widgets decomposed.
Resources properly disposed.
ListView.builder used for dynamic lists.
Images cached appropriately.
Responsive design implemented.
Error handling in place.
Accessibility labels added.
No dead code or unused imports.
