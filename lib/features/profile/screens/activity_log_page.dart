import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/auth_controller.dart';
import '../controllers/activity_controller.dart';
import '../../../design_system/modern_ui_system.dart';

class ActivityLogPage extends StatefulWidget {
  const ActivityLogPage({super.key});

  @override
  State<ActivityLogPage> createState() => _ActivityLogPageState();
}

class _ActivityLogPageState extends State<ActivityLogPage> {
  @override
  void initState() {
    super.initState();
    final uid = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>().userId
        : null;
    if (uid != null) {
      Get.find<ActivityController>().loadActivities(uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ActivityController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Activity')),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Padding(
            padding: EdgeInsets.all(DesignTokens.md(context)),
            child: Column(
              children: List.generate(
                3,
                (_) => Padding(
                  padding: EdgeInsets.only(bottom: DesignTokens.sm(context)),
                  child: SkeletonLoader(
                    height: DesignTokens.xl(context),
                  ),
                ),
              ),
            ),
          );
        }
        return OptimizedListView(
          itemCount: controller.logs.length,
          padding: EdgeInsets.all(DesignTokens.md(context)),
          itemBuilder: (context, index) {
            final log = controller.logs[index];
            return ListTile(
              title: Text(log.actionType),
              subtitle: Text(log.createdAt.toString()),
            );
          },
        );
      }),
    );
  }
}
