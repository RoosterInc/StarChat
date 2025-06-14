import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:appwrite/appwrite.dart';
import 'package:myapp/features/profile/controllers/profile_controller.dart';
import 'package:myapp/features/profile/services/profile_service.dart';
import 'package:myapp/features/profile/models/user_profile.dart';
import 'package:myapp/controllers/auth_controller.dart';

class FakeProfileService extends ProfileService {
  FakeProfileService()
      : super(
          databases: Databases(Client()),
          databaseId: 'db',
          profilesCollection: 'profiles',
          followsCollection: 'follows',
          blocksCollection: 'blocked_users',
        );
  UserProfile? profile;
  bool followed = false;
  bool unfollowed = false;
  bool blocked = false;
  bool following = false;
  int followerCountVal = 0;

  @override
  Future<UserProfile> fetchProfile(String userId) async {
    return profile!;
  }

  @override
  Future<bool> isFollowing(String followerId, String followedId) async {
    return following;
  }

  @override
  Future<int> getFollowerCount(String userId) async {
    return followerCountVal;
  }

  @override
  Future<void> followUser(String followerId, String followedId) async {
    followed = true;
    following = true;
    followerCountVal++;
  }

  @override
  Future<void> unfollowUser(String followerId, String followedId) async {
    unfollowed = true;
    following = false;
    if (followerCountVal > 0) followerCountVal--;
  }

  @override
  Future<void> blockUser(String blockerId, String blockedId) async {
    blocked = true;
  }

  @override
  Future<void> unblockUser(String blockerId, String blockedId) async {
    blocked = false;
  }
}

class FakeAuthController extends AuthController {
  FakeAuthController() {
    userId = 'u1';
  }
}

void main() {
  test('loadProfile sets profile', () async {
    final service = FakeProfileService();
    service.profile = UserProfile(id: '1', username: 'user');
    Get.put<ProfileService>(service);
    final controller = ProfileController();
    await controller.loadProfile('1');
    expect(controller.profile.value?.username, 'user');
  });

  test('loadProfile loads follow state and count', () async {
    final service = FakeProfileService();
    service.profile = UserProfile(id: '1', username: 'user');
    service.following = true;
    service.followerCountVal = 3;
    Get.put<ProfileService>(service);
    Get.put<AuthController>(FakeAuthController());
    final controller = ProfileController();
    await controller.loadProfile('1');
    expect(controller.isFollowing.value, isTrue);
    expect(controller.followerCount.value, 3);
  });

  test('followUser calls service', () async {
    final service = FakeProfileService();
    service.profile = UserProfile(id: '1', username: 'user');
    Get.put<ProfileService>(service);
    Get.put<AuthController>(FakeAuthController());
    final controller = ProfileController();
    await controller.followUser('1');
    expect(service.followed, isTrue);
    expect(controller.isFollowing.value, isTrue);
    expect(controller.followerCount.value, 1);
  });

  test('unfollowUser calls service', () async {
    final service = FakeProfileService();
    service.profile = UserProfile(id: '1', username: 'user');
    service.following = true;
    service.followerCountVal = 2;
    Get.put<ProfileService>(service);
    Get.put<AuthController>(FakeAuthController());
    final controller = ProfileController();
    await controller.unfollowUser('1');
    expect(service.unfollowed, isTrue);
    expect(controller.isFollowing.value, isFalse);
    expect(controller.followerCount.value, 1);
  });

  test('blockUser calls service', () async {
    final service = FakeProfileService();
    service.profile = UserProfile(id: '2', username: 'other');
    Get.put<ProfileService>(service);
    Get.put<AuthController>(FakeAuthController());
    final controller = ProfileController();
    await controller.blockUser('2');
    expect(service.blocked, isTrue);
  });

  test('unblockUser calls service', () async {
    final service = FakeProfileService();
    service.profile = UserProfile(id: '2', username: 'other');
    service.blocked = true;
    Get.put<ProfileService>(service);
    Get.put<AuthController>(FakeAuthController());
    final controller = ProfileController();
    await controller.unblockUser('2');
    expect(service.blocked, isFalse);
  });
}
