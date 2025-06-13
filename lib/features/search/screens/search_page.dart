import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/search_controller.dart' as my;

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
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(labelText: 'Search users'),
              onChanged: (q) => searchController.searchUsers(q),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Obx(() => searchController.isLoading.value
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: searchController.searchResults.length,
                      itemBuilder: (context, index) {
                        final user = searchController.searchResults[index];
                        return ListTile(
                          title: Text(user.username),
                          subtitle: user.bio != null ? Text(user.bio!) : null,
                        );
                      },
                    )),
            ),
          ],
        ),
      ),
    );
  }
}
