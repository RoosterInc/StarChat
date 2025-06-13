import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:appwrite/appwrite.dart';
import 'package:myapp/features/search/controllers/search_controller.dart';
import 'package:myapp/features/search/services/search_service.dart';
import 'package:myapp/features/profile/models/user_profile.dart';

class FakeSearchService extends SearchService {
  FakeSearchService()
      : super(
          databases: Databases(Client()),
          databaseId: 'db',
          profilesCollection: 'profiles',
          namesHistoryCollection: 'history',
        );

  List<UserProfile> result = [];

  @override
  Future<List<UserProfile>> searchUsers(String query) async {
    return result;
  }
}

void main() {
  test('searchUsers updates list', () async {
    final service = FakeSearchService();
    service.result = [UserProfile(id: '1', username: 'test')];
    Get.put<SearchService>(service);
    final controller = SearchController();
    await controller.searchUsers('t');
    expect(controller.searchResults.length, 1);
  });
}
