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
        Tab(text: 'Home', icon: Icon(Icons.home, size: 16)),
        Tab(text: 'Requests', icon: Icon(Icons.assignment, size: 16)),
        Tab(text: 'Questions', icon: Icon(Icons.help_outline, size: 16)),
        Tab(text: 'Events', icon: Icon(Icons.event, size: 16)),
        Tab(text: 'Messages', icon: Icon(Icons.message, size: 16)),
        Tab(text: 'Predictions', icon: Icon(Icons.auto_awesome, size: 16)),
      ];
    } else {
      return const [
        Tab(text: 'Home', icon: Icon(Icons.home, size: 16)),
        Tab(text: 'Feed', icon: Icon(Icons.dynamic_feed, size: 16)),
        Tab(text: 'Events', icon: Icon(Icons.event, size: 16)),
        Tab(text: 'Predictions', icon: Icon(Icons.auto_awesome, size: 16)),
        Tab(text: 'Messages', icon: Icon(Icons.message, size: 16)),
      ];
    }
  }
}
