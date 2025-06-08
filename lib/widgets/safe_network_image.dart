import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class SafeNetworkImage extends StatelessWidget {
  final String? imageUrl;
  final Widget? placeholder;
  final Widget? errorWidget;
  final double? width;
  final double? height;
  final BoxFit? fit;

  const SafeNetworkImage({
    super.key,
    required this.imageUrl,
    this.placeholder,
    this.errorWidget,
    this.width,
    this.height,
    this.fit,
  });

  // Custom cache manager with size and time limits
  static final CacheManager _cacheManager = CacheManager(
    Config(
      'profileImageCache',
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 100,
      repo: JsonCacheInfoRepository(databaseName: 'profileImageCache'),
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return errorWidget ?? const Icon(Icons.person);
    }

    return CachedNetworkImage(
      imageUrl: imageUrl!,
      cacheManager: _cacheManager,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) =>
          placeholder ?? const CircularProgressIndicator(),
      errorWidget: (context, url, error) {
        debugPrint('SafeNetworkImage error: $error for URL: $url');
        return errorWidget ?? const Icon(Icons.person);
      },
      fadeInDuration: const Duration(milliseconds: 200),
      fadeOutDuration: const Duration(milliseconds: 200),
      errorListener: (exception) {
        debugPrint('SafeNetworkImage exception: $exception');
      },
    );
  }

  // Method to clear cache when needed
  static Future<void> clearCache() async {
    await _cacheManager.emptyCache();
  }
}
