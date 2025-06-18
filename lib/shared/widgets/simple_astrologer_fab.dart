import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../features/profile/controllers/user_type_controller.dart';

class SimpleAstrologerFAB extends StatefulWidget {
  const SimpleAstrologerFAB({super.key});

  @override
  State<SimpleAstrologerFAB> createState() => _SimpleAstrologerFABState();
}

class _SimpleAstrologerFABState extends State<SimpleAstrologerFAB> {
  bool _showMenu = false;
  final userTypeController = Get.put(UserTypeController());

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!userTypeController.isAstrologerRx.value) {
        return const SizedBox.shrink();
      }

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_showMenu) ...[
            _buildMenuItem(
              context,
              'Create Prediction',
              Icons.auto_awesome,
              _handleCreatePrediction,
            ),
            const SizedBox(height: 8),
            _buildMenuItem(
              context,
              'Create Post',
              Icons.post_add,
              _handleCreatePost,
            ),
            const SizedBox(height: 16),
          ],
          FloatingActionButton(
            onPressed: _toggleMenu,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Icon(
              _showMenu ? Icons.close : Icons.add,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ],
      );
    });
  }

  Widget _buildMenuItem(
      BuildContext context, String label, IconData icon, VoidCallback onTap) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: FloatingActionButton.extended(
        onPressed: () {
          _toggleMenu();
          onTap();
        },
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }

  void _toggleMenu() {
    setState(() {
      _showMenu = !_showMenu;
    });
    HapticFeedback.lightImpact();
  }

  void _handleCreatePrediction() {
    Get.snackbar(
      'Create Prediction',
      'Navigate to prediction creation page',
      snackPosition: SnackPosition.BOTTOM,
      icon: const Icon(Icons.auto_awesome),
    );
  }

  void _handleCreatePost() {
    Get.snackbar(
      'Create Post',
      'Navigate to post creation page',
      snackPosition: SnackPosition.BOTTOM,
      icon: const Icon(Icons.post_add),
    );
  }
}
