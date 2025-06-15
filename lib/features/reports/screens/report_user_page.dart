import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../reports/services/report_service.dart';
import '../models/report_type.dart';
import '../../authentication/controllers/auth_controller.dart';
import '../../../core/design_system/modern_ui_system.dart';

class ReportUserPage extends StatefulWidget {
  final String userId;
  const ReportUserPage({super.key, required this.userId});

  @override
  State<ReportUserPage> createState() => _ReportUserPageState();
}

class _ReportUserPageState extends State<ReportUserPage> {
  final _descController = TextEditingController();
  ReportType _type = ReportType.spam;

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Report User')),
      body: Padding(
        padding: EdgeInsets.all(DesignTokens.md(context)),
        child: Column(
          children: [
            DropdownButtonFormField<ReportType>(
              value: _type,
              decoration: const InputDecoration(labelText: 'Type'),
              items: const [
                DropdownMenuItem(value: ReportType.spam, child: Text('Spam')),
                DropdownMenuItem(
                    value: ReportType.harassment, child: Text('Harassment')),
                DropdownMenuItem(value: ReportType.nudity, child: Text('Nudity')),
                DropdownMenuItem(value: ReportType.other, child: Text('Other')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _type = v);
              },
            ),
            SizedBox(height: DesignTokens.md(context)),
            TextField(
              controller: _descController,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(hintText: 'Description'),
            ),
            SizedBox(height: DesignTokens.md(context)),
            Row(
              children: [
                const Spacer(),
                AnimatedButton(
                  onPressed: () async {
                    final uid = auth.userId;
                    if (uid == null) {
                      Get.snackbar('Error', 'Login required');
                      return;
                    }
                    if (uid == widget.userId) {
                      Get.snackbar('Error', 'You cannot report yourself');
                      return;
                    }
                    try {
                      await Get.find<ReportService>().reportUser(
                        uid,
                        widget.userId,
                        _type,
                        _descController.text,
                      );
                      Get.snackbar('Reported', 'User reported for review');
                      Get.back();
                    } catch (_) {
                      Get.snackbar('Error', 'Failed to submit report');
                    }
                  },
                  child: const Text('Submit'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
