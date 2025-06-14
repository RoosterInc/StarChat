import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:appwrite/appwrite.dart';
import 'package:myapp/features/profile/models/user_profile.dart' as profile;
import 'package:myapp/features/search/controllers/search_controller.dart' as my;
import 'package:myapp/features/search/screens/search_page.dart';
import 'package:myapp/features/search/services/search_service.dart' as srv;
import 'package:myapp/design_system/modern_ui_system.dart'
    show MD3ThemeSystem, SkeletonLoader;

void main() {
  testWidgets('renders search page', (tester) async {
    Get.put(my.SearchController());
    await tester.pumpWidget(const GetMaterialApp(home: SearchPage()));
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('shows skeleton loader while loading', (tester) async {
    class DelayedSearchService extends srv.SearchService {
      DelayedSearchService()
          : super(
              databases: Databases(Client()),
              databaseId: 'db',
              profilesCollection: 'profiles',
              namesHistoryCollection: 'history',
            );

      @override
      Future<List<profile.UserProfile>> searchUsers(String query) {
        return Future.delayed(const Duration(milliseconds: 100), () => []);
      }
    }

    Get.put<srv.SearchService>(DelayedSearchService());
    final controller = my.SearchController();
    Get.put<my.SearchController>(controller);

    await tester.pumpWidget(
      GetMaterialApp(
        theme: MD3ThemeSystem.createTheme(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        home: const SearchPage(),
      ),
    );

    await tester.enterText(find.byType(TextField), 'user');
    await tester.pump();
    expect(find.byType(SkeletonLoader), findsWidgets);
  });
}
