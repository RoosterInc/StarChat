import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/auth_controller.dart';
import '../../../design_system/modern_ui_system.dart';
import '../controllers/profile_controller.dart';
import '../services/profile_service.dart';

class BlockedUsersPage extends StatefulWidget {
  const BlockedUsersPage({super.key});

  @override
  State<BlockedUsersPage> createState() => _BlockedUsersPageState();
}

class _BlockedUsersPageState extends State<BlockedUsersPage> {
  final _blockedIds = <String>[];
  var _isLoading = true;

  @override
  void initState() {
    super.initState();
    final uid =
        Get.isRegistered<AuthController>() ? Get.find<AuthController>().userId : null;
    if (uid != null) {
      final service = Get.find<ProfileService>();
      _blockedIds.addAll(service.getBlockedIds(uid));
    }
    _isLoading = false;
  }

  Future<void> _unblock(String id) async {
    await Get.find<ProfileController>().unblockUser(id);
    setState(() {
      _blockedIds.remove(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Blocked Users')),
      body: _isLoading
          ? Padding(
              padding: EdgeInsets.all(DesignTokens.md(context)),
              child: Column(
                children: List.generate(
                  3,
                  (_) => Padding(
                    padding: EdgeInsets.only(bottom: DesignTokens.sm(context)),
                    child: SkeletonLoader(height: DesignTokens.xl(context)),
                  ),
                ),
              ),
            )
          : OptimizedListView(
              itemCount: _blockedIds.length,
              padding: EdgeInsets.all(DesignTokens.md(context)),
              itemBuilder: (context, index) {
                final id = _blockedIds[index];
                return ListTile(
                  title: Text(id),
                  trailing: AnimatedButton(
                    onPressed: () => _unblock(id),
                    style: FilledButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: DesignTokens.md(context),
                        vertical: DesignTokens.sm(context),
                      ),
                    ),
                    child: const Text('Unblock'),
                  ),
                );
              },
            ),
    );
  }
}
