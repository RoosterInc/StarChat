import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../design_system/modern_ui_system.dart';
import '../controllers/moderation_controller.dart';
import '../models/report.dart';

class ModerationDashboard extends StatefulWidget {
  const ModerationDashboard({super.key});

  @override
  State<ModerationDashboard> createState() => _ModerationDashboardState();
}

class _ModerationDashboardState extends State<ModerationDashboard> {
  @override
  void initState() {
    super.initState();
    Get.find<ModerationController>().loadReports();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ModerationController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Moderation Dashboard')),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Padding(
            padding: EdgeInsets.all(DesignTokens.md(context)),
            child: Column(
              children: List.generate(
                3,
                (_) => Padding(
                  padding: EdgeInsets.only(bottom: DesignTokens.sm(context)),
                  child: const SkeletonLoader(height: 80),
                ),
              ),
            ),
          );
        }
        if (!controller.isModerator.value) {
          return const Center(child: Text('Access denied'));
        }
        return OptimizedListView(
          itemCount: controller.reports.length,
          padding: EdgeInsets.all(DesignTokens.md(context)),
          itemBuilder: (context, index) {
            final report = controller.reports[index];
            return Padding(
              padding: EdgeInsets.only(bottom: DesignTokens.sm(context)),
              child: _ReportCard(report: report, onAction: controller.reviewReport),
            );
          },
        );
      }),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final Report report;
  final void Function(Report, String) onAction;

  const _ReportCard({required this.report, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return GlassmorphicCard(
      padding: DesignTokens.md(context).all,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Type: ${report.reportType}', style: Theme.of(context).textTheme.titleMedium),
          SizedBox(height: DesignTokens.xs(context)),
          Text(report.description),
          SizedBox(height: DesignTokens.sm(context)),
          Row(
            children: [
              AnimatedButton(
                onPressed: () => onAction(report, 'dismissed'),
                child: const Text('Dismiss'),
              ),
              SizedBox(width: DesignTokens.sm(context)),
              AnimatedButton(
                onPressed: () => onAction(report, 'action_taken'),
                child: const Text('Take Action'),
              ),
            ],
          )
        ],
      ),
    );
  }
}
