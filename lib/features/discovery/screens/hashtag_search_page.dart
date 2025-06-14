import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../social_feed/services/feed_service.dart';
import '../../social_feed/widgets/post_card.dart';
import '../../social_feed/models/feed_post.dart';
import '../../../design_system/modern_ui_system.dart';

class HashtagSearchPage extends StatefulWidget {
  final String hashtag;
  const HashtagSearchPage({super.key, required this.hashtag});

  @override
  State<HashtagSearchPage> createState() => _HashtagSearchPageState();
}

class _HashtagSearchPageState extends State<HashtagSearchPage> {
  final _posts = <FeedPost>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final service = Get.find<FeedService>();
    final posts = await service.getPostsByHashtag(widget.hashtag);
    setState(() {
      _posts.clear();
      _posts.addAll(posts);
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('#${widget.hashtag}')),
      body: _loading
          ? Padding(
              padding: EdgeInsets.all(DesignTokens.md(context)),
              child: Column(
                children: List.generate(
                  3,
                  (_) => Padding(
                    padding: EdgeInsets.only(bottom: DesignTokens.sm(context)),
                    child: SkeletonLoader(
                      height: DesignTokens.xl(context),
                    ),
                  ),
                ),
              ),
            )
          : OptimizedListView(
              itemCount: _posts.length,
              padding: EdgeInsets.all(DesignTokens.md(context)),
              itemBuilder: (context, index) {
                final post = _posts[index];
                return Padding(
                  padding: EdgeInsets.only(bottom: DesignTokens.sm(context)),
                  child: PostCard(post: post),
                );
              },
            ),
    );
  }
}
