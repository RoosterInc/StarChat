import 'package:get/get.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../features/authentication/controllers/auth_controller.dart';
import '../features/search/services/search_service.dart';
import '../features/search/controllers/search_controller.dart';

class SearchBinding extends Bindings {
  @override
  void dependencies() {
    final auth = Get.find<AuthController>();
    Get.lazyPut<SearchService>(() => SearchService(
          databases: auth.databases,
          databaseId: dotenv.env['APPWRITE_DATABASE_ID'] ?? 'StarChat_DB',
          profilesCollection: dotenv.env['USER_PROFILES_COLLECTION_ID'] ?? 'user_profiles',
          namesHistoryCollection: dotenv.env['USER_NAMES_HISTORY_COLLECTION_ID'] ?? 'user_names_history',
        ));
    Get.lazyPut<SearchController>(() => SearchController());
  }
}
