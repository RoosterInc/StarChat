import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/user_type_controller.dart';

class SimpleDynamicTabs extends StatelessWidget {
  const SimpleDynamicTabs({super.key});

  @override
  Widget build(BuildContext context) {
    final userTypeController = Get.put(UserTypeController());

    return Obx(() {
      final isAstrologer = userTypeController.isAstrologer.value;
      final tabs = _getTabsForUserType(isAstrologer);

      return TabBar(
        isScrollable: tabs.length > 5,
        tabs: tabs,
      );
    });
  }

  List<Tab> _getTabsForUserType(bool isAstrologer) {
    if (isAstrologer) {
      return const [
        Tab(text: 'Home'),
        Tab(text: 'Requests'),
        Tab(text: 'Questions'),
        Tab(text: 'Events'),
        Tab(text: 'Messages'),
        Tab(text: 'Predictions'),
      ];
    } else {
      return const [
        Tab(text: 'Home'),
        Tab(text: 'Feed'),
        Tab(text: 'Events'),
        Tab(text: 'Predictions'),
        Tab(text: 'Messages'),
      ];
    }
  }
}
