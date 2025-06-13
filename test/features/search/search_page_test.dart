import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:myapp/features/search/controllers/search_controller.dart';
import 'package:myapp/features/search/screens/search_page.dart';

void main() {
  testWidgets('renders search page', (tester) async {
    Get.put(SearchController());
    await tester.pumpWidget(const GetMaterialApp(home: SearchPage()));
    expect(find.byType(TextField), findsOneWidget);
  });
}
