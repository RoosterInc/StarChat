import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../reports/services/report_service.dart';
import '../models/report_type.dart';
import '../../../controllers/auth_controller.dart';
import '../../../design_system/modern_ui_system.dart';

class ReportPostPage extends StatefulWidget {
  final String postId;
  const ReportPostPage({super.key, required this.postId});

  @override
  State<ReportPostPage> createState() => _ReportPostPageState();
}

class _ReportPostPageState extends State<ReportPostPage> {
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
      appBar: AppBar(title: const Text('Report Post')),
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
                    try {
                      await Get.find<ReportService>().reportPost(
                        uid,
                        widget.postId,
                        _type,
                        _descController.text,
                      );
                      Get.snackbar('Reported', 'Post reported for review');
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
