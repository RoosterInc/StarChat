import 'package:flutter/material.dart';
import '../../../design_system/modern_ui_system.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MediaGallery extends StatelessWidget {
  final List<String> urls;
  const MediaGallery({super.key, required this.urls});

  @override
  Widget build(BuildContext context) {
    if (urls.isEmpty) return const SizedBox();
    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: urls.length,
        separatorBuilder: (_, __) => SizedBox(width: DesignTokens.sm(context)),
        itemBuilder: (context, index) {
          final url = urls[index];
          return ClipRRect(
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd(context)),
            child: CachedNetworkImage(
              imageUrl: url,
              width: 200,
              height: 200,
              fit: BoxFit.cover,
              placeholder: (context, url) => SkeletonLoader(
                width: 200,
                height: 200,
                borderRadius:
                    BorderRadius.circular(DesignTokens.radiusMd(context)),
              ),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),
          );
        },
      ),
    );
  }
}
