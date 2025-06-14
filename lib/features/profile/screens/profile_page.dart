import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/profile_controller.dart';
import '../../../controllers/auth_controller.dart';
import '../services/profile_service.dart';
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
          return Center(child: SkeletonLoader(height: DesignTokens.xl(context), width: DesignTokens.xl(context)));
        }
        final profile = controller.profile.value;
        if (profile == null) {
          return const Center(child: Text('Profile not found'));
        }
        final isFollowing = controller.isFollowing.value;
        final count = controller.followerCount.value;
        return EnhancedResponsiveLayout(
          mobile: (context) =>
              _buildPortraitLayout(context, profile, isFollowing, count),
          mobileLandscape: (context) =>
              _buildLandscapeLayout(context, profile, isFollowing, count),
          tablet: (context) =>
              _buildLandscapeLayout(context, profile, isFollowing, count),
          tabletLandscape: (context) =>
              _buildLandscapeLayout(context, profile, isFollowing, count),
          desktop: (context) =>
              _buildLandscapeLayout(context, profile, isFollowing, count),
          desktopLandscape: (context) =>
              _buildLandscapeLayout(context, profile, isFollowing, count),
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

  double _halfSpacing(BuildContext context) {
    return ResponsiveUtils.adaptiveValue(
      context,
      mobile: DesignTokens.xs(context),
      tablet: DesignTokens.sm(context),
      desktop: DesignTokens.spacing(context, 12),
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

  Widget _buildPortraitLayout(
      BuildContext context, UserProfile profile, bool isFollowing, int count) {
    final spacing = _spacing(context);
    final halfSpacing = _halfSpacing(context);
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
            _buildFollowButton(context, profile.id, isFollowing),
            SizedBox(height: halfSpacing),
            Text('Followers: \$count'),
            SizedBox(height: halfSpacing),
            if (Get.find<AuthController>().userId != null &&
                Get.find<AuthController>().userId != profile.id)
              _buildBlockButton(context, profile.id),
            if (Get.find<AuthController>().userId != null &&
                Get.find<AuthController>().userId != profile.id)
              Padding(
                padding: EdgeInsets.only(top: halfSpacing),
                child: _buildReportButton(context, profile.id),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLandscapeLayout(
      BuildContext context, UserProfile profile, bool isFollowing, int count) {
    final spacing = _spacing(context);
    final halfSpacing = _halfSpacing(context);
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
                _buildFollowButton(context, profile.id, isFollowing),
                SizedBox(height: halfSpacing),
                Text('Followers: \$count'),
                SizedBox(height: halfSpacing),
                if (Get.find<AuthController>().userId != null &&
                    Get.find<AuthController>().userId != profile.id)
                  _buildBlockButton(context, profile.id),
                if (Get.find<AuthController>().userId != null &&
                    Get.find<AuthController>().userId != profile.id)
                  Padding(
                    padding: EdgeInsets.only(top: halfSpacing),
                    child: _buildReportButton(context, profile.id),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFollowButton(
      BuildContext context, String uid, bool isFollowing) {
    return AnimatedButton(
      onPressed: () async {
        final controller = Get.find<ProfileController>();
        if (isFollowing) {
          await controller.unfollowUser(uid);
        } else {
          await controller.followUser(uid);
        }
      },
      style: FilledButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: DesignTokens.md(context),
          vertical: DesignTokens.sm(context),
        ),
      ),
      child: Text(isFollowing ? 'Unfollow' : 'Follow'),
    );
  }

  Widget _buildBlockButton(BuildContext context, String uid) {
    return AnimatedButton(
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
    );
  }

  Widget _buildReportButton(BuildContext context, String uid) {
    return AnimatedButton(
      onPressed: () {
        Get.to(
          () => ReportUserPage(userId: uid),
          binding: ReportBinding(),
        );
      },
      child: const Text('Report'),
    );
  }
}
