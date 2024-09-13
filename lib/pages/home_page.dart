import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';

class HomePage extends GetView<AuthController> {
  @override
  Widget build(BuildContext context) {
    // Use MediaQuery to get screen size
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: Text('home_page'.tr),
      ),
      body: Center(
        child: Container(
          padding: EdgeInsets.all(16),
          width: size.width * 0.9 > 600 ? 600 : size.width * 0.9,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'signed_in'.tr,
                style: TextStyle(fontSize: 24),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  await controller.account.deleteSession(sessionId: 'current');
                  controller.clearControllers();
                  controller.isOTPSent.value = false;
                  Get.offAllNamed('/');
                },
                child: Text('logout'.tr),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  _showDeleteAccountDialog(context);
                },
                child: Text('delete_account'.tr),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('delete_account'.tr),
          content: Text('delete_account_confirmation'.tr),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text('cancel'.tr),
            ),
            TextButton(
              onPressed: () {
                Get.back();
                controller.deleteUserAccount();
              },
              child: Text('delete'.tr),
            ),
          ],
        );
      },
    );
  }
}
