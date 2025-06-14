import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:appwrite/appwrite.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:myapp/features/profile/screens/profile_page.dart';
import 'package:myapp/features/profile/controllers/profile_controller.dart';
import 'package:myapp/features/profile/services/profile_service.dart';
import 'package:myapp/features/profile/models/user_profile.dart';
import 'package:myapp/features/profile/services/activity_service.dart';
import 'package:myapp/design_system/modern_ui_system.dart';
import 'package:myapp/controllers/auth_controller.dart';

class DelayedProfileService extends FakeProfileService {
  @override
  Future<UserProfile> fetchProfile(String userId) {
    return Future.delayed(
        const Duration(milliseconds: 100), () => super.fetchProfile(userId));
  }
}

class FakeProfileService extends ProfileService {
  FakeProfileService()
      : super(
            databases: Databases(Client()),
            databaseId: 'db',
            profilesCollection: 'p',
            followsCollection: 'f',
            blocksCollection: 'b');

  UserProfile? profile;
  bool followed = false;
  bool unfollowed = false;

  @override
  Future<UserProfile> fetchProfile(String userId) async {
    return profile!;
  }

  @override
  Future<void> followUser(String followerId, String followedId) async {
    followed = true;
  }

  @override
  Future<void> unfollowUser(String followerId, String followedId) async {
    unfollowed = true;
  }

  @override
  bool isFollowing(String followerId, String followedId) =>
      followed && !unfollowed;
}

class FakeAuth extends AuthController {
  FakeAuth() {
    userId = 'u1';
  }

  @override
  Future<void> checkExistingSession({bool navigateOnMissing = true}) async {}
}

class StubActivityService extends ActivityService {
  StubActivityService()
      : super(
            databases: Databases(Client()),
            databaseId: 'db',
            collectionId: 'a');

  @override
  Future<void> logActivity(String userId, String actionType,
      {String? itemId, String? itemType}) async {}

  @override
  Future<List<Map<String, dynamic>>> fetchActivities(String userId) async => [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.testMode = true;
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('shows skeleton loader while loading', (tester) async {
    final service = DelayedProfileService();
    service.profile = UserProfile(id: '1', username: 'user');
    Get.put<ProfileService>(service);
    Get.put<AuthController>(FakeAuth());
    Get.put<ActivityService>(StubActivityService());
    Get.put<ProfileController>(ProfileController());

    await tester.pumpWidget(GetMaterialApp(
      theme: MD3ThemeSystem.createTheme(seedColor: Colors.blue),
      home: const UserProfilePage(userId: '1'),
    ));

    await tester.pump();
    expect(find.byType(SkeletonLoader), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 150));
  });

  testWidgets('follow/unfollow button text toggles', (tester) async {
    final service = FakeProfileService();
    service.profile = UserProfile(id: '1', username: 'user');
    Get.put<ProfileService>(service);
    Get.put<AuthController>(FakeAuth());
    Get.put<ActivityService>(StubActivityService());
    Get.put<ProfileController>(ProfileController());

    await tester.pumpWidget(GetMaterialApp(
      theme: MD3ThemeSystem.createTheme(seedColor: Colors.blue),
      home: const UserProfilePage(userId: '1'),
    ));

    await tester.pump();
    expect(find.text('Follow'), findsOneWidget);

    await tester.tap(find.text('Follow'));
    await tester.pump();
    expect(service.followed, isTrue);
    expect(find.text('Unfollow'), findsOneWidget);

    await tester.tap(find.text('Unfollow'));
    await tester.pump();
    expect(service.unfollowed, isTrue);
    expect(find.text('Follow'), findsOneWidget);
  });
}
