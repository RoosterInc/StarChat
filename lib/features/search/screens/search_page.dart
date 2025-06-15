import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/search_controller.dart' as my;
import '../../../core/design_system/modern_ui_system.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchController = Get.find<my.SearchController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Padding(
        padding: EdgeInsets.all(DesignTokens.md(context)),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(labelText: 'Search users'),
              onChanged: (q) => searchController.searchUsers(q),
            ),
            SizedBox(height: DesignTokens.md(context)),
            Expanded(
              child: Obx(() {
                if (searchController.isLoading.value) {
                  return Column(
                    children: List.generate(
                      3,
                      (_) => Padding(
                        padding: EdgeInsets.only(
                          bottom: DesignTokens.sm(context),
                        ),
                        child: SkeletonLoader(
                          height: DesignTokens.xl(context),
                        ),
                      ),
                    ),
                  );
                }
                return OptimizedListView(
                  itemCount: searchController.searchResults.length,
                  itemBuilder: (context, index) {
                    final user = searchController.searchResults[index];
                    return ListTile(
                      title: Text(user.username),
                      subtitle: user.bio != null ? Text(user.bio!) : null,
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
