import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/profile_controller.dart';
import '../../../controllers/auth_controller.dart';
import '../../reports/screens/report_user_page.dart';
import '../../../bindings/report_binding.dart';
import '../../../design_system/modern_ui_system.dart';
import '../../../widgets/enhanced_responsive_layout.dart';

class UserProfilePage extends StatefulWidget {
  final String userId;
  const UserProfilePage({super.key, required this.userId});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  @override
  void initState() {
    super.initState();
    Get.find<ProfileController>().loadProfile(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProfileController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: SkeletonLoader(
              height: DesignTokens.xl(context),
              width: DesignTokens.xl(context),
            ),
          );
        }
        final profile = controller.profile.value;
        if (profile == null) {
          return const Center(child: Text('Profile not found'));
        }
        return EnhancedResponsiveLayout(
          mobile: (context) => _buildPortraitLayout(context, profile),
          mobileLandscape: (context) => _buildLandscapeLayout(context, profile),
          tablet: (context) => _buildPortraitLayout(context, profile),
          tabletLandscape: (context) => _buildLandscapeLayout(context, profile),
          desktop: (context) => _buildLandscapeLayout(context, profile),
          desktopLandscape: (context) => _buildLandscapeLayout(context, profile),
        );
      }),
    );
  }

  double _spacing(BuildContext context) {
    return ResponsiveUtils.adaptiveValue(
      context,
      mobile: DesignTokens.sm(context),
      tablet: DesignTokens.md(context),
      desktop: DesignTokens.lg(context),
    );
  }

  EdgeInsets _pagePadding(BuildContext context) {
    final value = ResponsiveUtils.adaptiveValue(
      context,
      mobile: DesignTokens.md(context),
      tablet: DesignTokens.lg(context),
      desktop: DesignTokens.xl(context),
    );
    return EdgeInsets.all(value);
  }

  Widget _buildPortraitLayout(BuildContext context, UserProfile profile) {
    final spacing = _spacing(context);
    return SingleChildScrollView(
      padding: _pagePadding(context),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              profile.username,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (profile.bio != null)
              Padding(
                padding: EdgeInsets.only(top: spacing),
                child: Text(profile.bio!),
              ),
            SizedBox(height: spacing),
            _buildFollowButton(context, profile.id),
            SizedBox(height: spacing * 0.5),
            _buildBlockButton(context, profile.id),
            if (_shouldShowReport())
              Padding(
                padding: EdgeInsets.only(top: spacing * 0.5),
                child: _buildReportButton(context, profile.id),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLandscapeLayout(BuildContext context, UserProfile profile) {
    final spacing = _spacing(context);
    return SingleChildScrollView(
      padding: _pagePadding(context),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.username,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  if (profile.bio != null)
                    Padding(
                      padding: EdgeInsets.only(top: spacing),
                      child: Text(profile.bio!),
                    ),
                ],
              ),
            ),
            SizedBox(width: spacing),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildFollowButton(context, profile.id),
                SizedBox(height: spacing * 0.5),
                _buildBlockButton(context, profile.id),
                if (_shouldShowReport())
                  Padding(
                    padding: EdgeInsets.only(top: spacing * 0.5),
                    child: _buildReportButton(context, profile.id),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFollowButton(BuildContext context, String uid) {
    return Semantics(
      label: 'Follow user',
      child: AnimatedButton(
        onPressed: () => Get.find<ProfileController>().followUser(uid),
        style: FilledButton.styleFrom(
          padding: EdgeInsets.symmetric(
            horizontal: DesignTokens.md(context),
            vertical: DesignTokens.sm(context),
          ),
        ),
        child: const Text('Follow'),
      ),
    );
  }

  Widget _buildBlockButton(BuildContext context, String uid) {
    return Semantics(
      label: 'Block user',
      child: AnimatedButton(
        onPressed: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Block User'),
              content: const Text('Are you sure you want to block this user?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Block'),
                ),
              ],
            ),
          );
          if (confirm == true) {
            await Get.find<ProfileController>().blockUser(uid);
          }
        },
        child: const Text('Block'),
      ),
    );
  }

  Widget _buildReportButton(BuildContext context, String uid) {
    return Semantics(
      label: 'Report user',
      child: AnimatedButton(
        onPressed: () {
          Get.to(
            () => ReportUserPage(userId: uid),
            binding: ReportBinding(),
          );
        },
        child: const Text('Report'),
      ),
    );
  }

  bool _shouldShowReport() {
    final auth = Get.find<AuthController>();
    final current = auth.userId;
    return current != null && current != widget.userId;
  }
}
