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
  bool blocked = false;

  @override
  Future<UserProfile> fetchProfile(String userId) async {
    return profile!;
  }

  @override
  Future<void> followUser(String followerId, String followedId) async {
    followed = true;
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
  @override
  String? userId = 'u1';
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

  test('followUser calls service', () async {
    final service = FakeProfileService();
    service.profile = UserProfile(id: '1', username: 'user');
    Get.put<ProfileService>(service);
    Get.put<AuthController>(FakeAuthController());
    final controller = ProfileController();
    await controller.followUser('1');
    expect(service.followed, isTrue);
  });
}
