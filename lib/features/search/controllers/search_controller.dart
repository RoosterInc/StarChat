import 'package:get/get.dart';
import '../../profile/models/user_profile.dart';
import '../services/search_service.dart';

class SearchController extends GetxController {
  var searchResults = <UserProfile>[].obs;
  var isLoading = false.obs;

  Future<void> searchUsers(String query) async {
    if (query.isEmpty) return;
    isLoading.value = true;
    try {
      searchResults.value = await Get.find<SearchService>().searchUsers(query);
    } finally {
      isLoading.value = false;
    }
  }
}
