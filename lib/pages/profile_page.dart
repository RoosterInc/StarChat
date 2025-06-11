// lib/pages/profile_page.dart
// Modern profile page with glassmorphism and enhanced UX

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../controllers/auth_controller.dart';
import '../controllers/user_type_controller.dart';
import '../controllers/theme_controller.dart';
import '../design_system/modern_ui_system.dart';
import '../widgets/safe_network_image.dart';
import '../widgets/enhanced_responsive_layout.dart' as enhanced_layout;
import 'package:package_info_plus/package_info_plus.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: DesignTokens.durationNormal,
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: DesignTokens.curveEaseOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: DesignTokens.curveEaseOut,
    ));

    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final userTypeController = Get.find<UserTypeController>();

    return Scaffold(
      body: AnimatedBuilder(
        animation: _slideController,
        builder: (context, child) {
          return SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: CustomScrollView(
                slivers: [
                  _buildModernAppBar(context),
                  SliverPadding(
                    padding:
                        enhanced_layout.ResponsiveUtils.getResponsivePadding(
                      context,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildProfileHeader(context, authController, userTypeController),
                        SizedBox(height: DesignTokens.xl(context)),
                        _buildProfileActions(context, authController),
                        SizedBox(height: DesignTokens.xl(context)),
                        _buildUserTypeSection(context, userTypeController),
                        SizedBox(height: DesignTokens.xl(context)),
                        _buildSettingsSection(context),
                        SizedBox(height: DesignTokens.xxl(context)),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildModernAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 100,
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      leading: AnimatedButton(
        onPressed: () => Get.back(),
        child: Icon(
          Icons.arrow_back_rounded,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      actions: [
        AnimatedButton(
          onPressed: () => Get.toNamed('/settings'),
          child: Icon(
            Icons.settings_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        SizedBox(width: DesignTokens.md(context)),
      ],
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          'profile'.tr,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.1),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, AuthController authController,
      UserTypeController userTypeController) {
    return GlassmorphicCard(
      padding: DesignTokens.xl(context).all,
      child: Obx(() => Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary.withOpacity(0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  GlassmorphicContainer(
                    width: 120,
                    height: 120,
                    borderRadius: BorderRadius.circular(60),
                    child: ClipOval(
                      child: SafeNetworkImage(
                        imageUrl: authController.profilePictureUrl.value,
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                        errorWidget: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).colorScheme.primary,
                                Theme.of(context).colorScheme.secondary,
                              ],
                            ),
                          ),
                          child: Icon(
                            Icons.person_rounded,
                            size: 60,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: AnimatedButton(
                      onPressed: () => _changePicture(authController),
                      child: Container(
                        padding: DesignTokens.sm(context).all,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context).colorScheme.secondary,
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.camera_alt_rounded,
                          color: Theme.of(context).colorScheme.onPrimary,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: DesignTokens.lg(context)),
              Text(
                authController.username.value.isNotEmpty
                    ? authController.username.value
                    : 'User',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: DesignTokens.sm(context)),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: DesignTokens.md(context),
                  vertical: DesignTokens.sm(context),
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primaryContainer,
                      Theme.of(context).colorScheme.secondaryContainer,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusLg(context)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      userTypeController.isAstrologerRx.value
                          ? Icons.auto_awesome_rounded
                          : Icons.person_rounded,
                      size: 16,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    SizedBox(width: DesignTokens.sm(context)),
                    Text(
                      userTypeController.userTypeRx.value,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          )),
    );
  }

  Widget _buildProfileActions(BuildContext context, AuthController authController) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context,
                icon: Icons.edit_rounded,
                title: 'change_username'.tr,
                subtitle: 'Update your display name',
                onTap: () => Get.toNamed('/set_username'),
                gradient: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
              ),
            ),
            SizedBox(width: DesignTokens.md(context)),
            Expanded(
              child: _buildActionCard(
                context,
                icon: Icons.photo_camera_rounded,
                title: 'change_picture'.tr,
                subtitle: 'Update profile photo',
                onTap: () => _changePicture(authController),
                gradient: [
                  Theme.of(context).colorScheme.tertiary,
                  Theme.of(context).colorScheme.primary,
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required List<Color> gradient,
  }) {
    return AnimatedButton(
      onPressed: onTap,
      child: GlassmorphicContainer(
        height: 120,
        padding: DesignTokens.lg(context).all,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg(context)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: DesignTokens.sm(context).all,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient),
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd(context)),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            SizedBox(height: DesignTokens.md(context)),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: DesignTokens.xs(context)),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserTypeSection(BuildContext context, UserTypeController userTypeController) {
    return GlassmorphicCard(
      padding: DesignTokens.lg(context).all,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: DesignTokens.sm(context).all,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.secondary,
                      Theme.of(context).colorScheme.tertiary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd(context)),
                ),
                child: Icon(
                  Icons.swap_horiz_rounded,
                  color: Theme.of(context).colorScheme.onSecondary,
                  size: 20,
                ),
              ),
              SizedBox(width: DesignTokens.md(context)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'User Type',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Switch between user types',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: DesignTokens.lg(context)),
          Obx(() => Column(
                children: [
                  _buildUserTypeOption(
                    context,
                    'General User',
                    'Standard user with access to predictions and chat',
                    isSelected: userTypeController.userTypeRx.value == 'General User',
                    onTap: () => _updateUserType(userTypeController, 'General User'),
                  ),
                  SizedBox(height: DesignTokens.sm(context)),
                  _buildUserTypeOption(
                    context,
                    'Astrologer',
                    'Create predictions and manage chats',
                    isSelected: userTypeController.userTypeRx.value == 'Astrologer',
                    onTap: () => _updateUserType(userTypeController, 'Astrologer'),
                  ),
                ],
              )),
        ],
      ),
    );
  }

  Widget _buildUserTypeOption(
    BuildContext context,
    String title,
    String description, {
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return AnimatedButton(
      onPressed: onTap,
      child: GlassmorphicContainer(
        padding: DesignTokens.md(context).all,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg(context)),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            SizedBox(width: DesignTokens.md(context)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    return GlassmorphicCard(
      padding: DesignTokens.lg(context).all,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: DesignTokens.sm(context).all,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.tertiary,
                      Theme.of(context).colorScheme.primary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd(context)),
                ),
                child: Icon(
                  Icons.settings_rounded,
                  color: Theme.of(context).colorScheme.onTertiary,
                  size: 20,
                ),
              ),
              SizedBox(width: DesignTokens.md(context)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Settings',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Personalize your experience',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: DesignTokens.lg(context)),
          Obx(() => _buildSettingsTile(
                context,
                icon: themeController.isDarkMode.value
                    ? Icons.dark_mode_rounded
                    : Icons.light_mode_rounded,
                title: 'dark_mode'.tr,
                subtitle: 'Toggle between light and dark themes',
                trailing: Switch(
                  value: themeController.isDarkMode.value,
                  onChanged: (_) => themeController.toggleTheme(),
                ),
              )),
          _buildSettingsTile(
            context,
            icon: Icons.notifications_rounded,
            title: 'push_notifications'.tr,
            subtitle: 'Receive updates and alerts',
            trailing: Switch(
              value: true,
              onChanged: (value) {
                Get.snackbar('Coming Soon', 'Notification settings will be available soon');
              },
            ),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.info_rounded,
            title: 'version'.tr,
            subtitle: 'App version information',
            trailing: FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                return Text(
                  snapshot.hasData ? snapshot.data!.version : '...',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                );
              },
            ),
            onTap: () {},
          ),
          const Divider(),
          _buildSettingsTile(
            context,
            icon: Icons.logout_rounded,
            title: 'logout'.tr,
            subtitle: 'Sign out of your account',
            isDestructive: true,
            onTap: () => _showLogoutDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    bool isDestructive = false,
  }) {
    return AnimatedButton(
      onPressed: onTap,
      child: Container(
        padding: DesignTokens.md(context).all,
        margin: EdgeInsets.only(bottom: DesignTokens.sm(context)),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd(context)),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDestructive
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            SizedBox(width: DesignTokens.md(context)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDestructive
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Future<void> _changePicture(AuthController authController) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (picked == null) return;

      final cropped = await ImageCropper().cropImage(
        sourcePath: picked.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Profile Picture',
            toolbarColor: Theme.of(context).colorScheme.primary,
            toolbarWidgetColor: Theme.of(context).colorScheme.onPrimary,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Crop Profile Picture',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
          ),
        ],
      );

      if (cropped != null) {
        final file = File(cropped.path);
        await authController.updateProfilePicture(file);
        MicroInteractions.mediumHaptic();
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update profile picture. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Theme.of(context).colorScheme.errorContainer,
        colorText: Theme.of(context).colorScheme.onErrorContainer,
      );
    }
  }

  Future<void> _updateUserType(UserTypeController controller, String type) async {
    if (controller.userTypeRx.value == type) return;

    MicroInteractions.lightHaptic();
    await Get.find<AuthController>().updateUserType(type);
  }

  void _showLogoutDialog(BuildContext context) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: GlassmorphicContainer(
          padding: DesignTokens.xl(context).all,
          borderRadius: BorderRadius.circular(DesignTokens.radiusXl(context)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.logout_rounded,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              SizedBox(height: DesignTokens.lg(context)),
              Text(
                'logout'.tr,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: DesignTokens.md(context)),
              Text(
                'logout_confirm'.tr,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: DesignTokens.xl(context)),
              Row(
                children: [
                  Expanded(
                    child: AnimatedButton(
                      onPressed: () => Get.back(),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          borderRadius: BorderRadius.circular(
                            DesignTokens.radiusLg(context),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'cancel'.tr,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: DesignTokens.md(context)),
                  Expanded(
                    child: AnimatedButton(
                      onPressed: () async {
                        Get.back();
                        await Get.find<AuthController>().logout();
                      },
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.error,
                              Theme.of(context).colorScheme.error.withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(
                            DesignTokens.radiusLg(context),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'logout'.tr,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onError,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
