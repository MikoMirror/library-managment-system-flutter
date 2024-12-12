import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../../features/books/models/book.dart';


class ImageCacheService {
  static final ImageCacheService _instance = ImageCacheService._internal();
  factory ImageCacheService() => _instance;
  ImageCacheService._internal();

  static const String _recentlyViewedKey = 'recently_viewed_books';
  static const int _maxRecentBooks = 50; // Adjust based on your needs
  
  final DefaultCacheManager _cacheManager = DefaultCacheManager();

  // Cache dimensions
  static const int memCacheWidth = 300;
  static const int memCacheHeight = 400;
  static const int maxWidthDiskCache = 600;
  static const int maxHeightDiskCache = 800;

  // Initialize cache settings
  Future<void> initializeCacheSettings() async {
    CachedNetworkImage.logLevel = CacheManagerLogLevel.debug;
    
    // Configure image cache size
    PaintingBinding.instance.imageCache.maximumSize = 1000;
    PaintingBinding.instance.imageCache.maximumSizeBytes = 1024 * 1024 * 100;

    // Preload recently viewed books
    await _preloadRecentlyViewedBooks();
  }

  // Track recently viewed books
  Future<void> trackBookView(Book book) async {
    if (book.coverUrl.isEmpty || book.coverUrl == 'placeholder_url') return;

    final prefs = await SharedPreferences.getInstance();
    final recentlyViewed = await _getRecentlyViewedUrls();

    // Add to front, remove duplicates, limit size
    recentlyViewed.remove(book.coverUrl);
    recentlyViewed.insert(0, book.coverUrl);
    if (recentlyViewed.length > _maxRecentBooks) {
      recentlyViewed.removeLast();
    }

    await prefs.setStringList(_recentlyViewedKey, recentlyViewed);
  }

  // Get recently viewed book URLs
  Future<List<String>> _getRecentlyViewedUrls() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_recentlyViewedKey) ?? [];
  }

  // Preload recently viewed books
  Future<void> _preloadRecentlyViewedBooks() async {
    final recentlyViewed = await _getRecentlyViewedUrls();
    for (final url in recentlyViewed) {
      await _ensureImageCached(url);
    }
  }

  // Ensure image is cached
  Future<void> _ensureImageCached(String url) async {
    try {
      final fileInfo = await _cacheManager.getFileFromCache(url);
      if (fileInfo == null) {
        await _cacheManager.downloadFile(url, key: url);
      }
    } catch (e) {
      debugPrint('Error caching image: $e');
    }
  }

  // Pre-cache book images with priority
  Future<void> preCacheBookImages(BuildContext context, List<Book> books) async {
    final recentlyViewed = await _getRecentlyViewedUrls();
    
    // Sort books by priority (recently viewed first)
    final sortedBooks = List<Book>.from(books)
      ..sort((a, b) {
        final aIndex = recentlyViewed.indexOf(a.coverUrl);
        final bIndex = recentlyViewed.indexOf(b.coverUrl);
        if (aIndex == -1 && bIndex == -1) return 0;
        if (aIndex == -1) return 1;
        if (bIndex == -1) return -1;
        return aIndex.compareTo(bIndex);
      });

    // Cache in order of priority
    for (final book in sortedBooks) {
      if (book.coverUrl.isNotEmpty && book.coverUrl != 'placeholder_url') {
        await _ensureImageCached(book.coverUrl);
      }
    }
  }

  // Build cached image widget with preloading
  Widget buildCachedImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    ImageWidgetBuilder? imageBuilder,
  }) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      cacheManager: _cacheManager,
      width: width,
      height: height,
      fit: fit,
      imageBuilder: imageBuilder ?? (context, imageProvider) {
        // Preload the next few images when this one is displayed
        _preloadNextImages();
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: imageProvider,
              fit: fit,
            ),
          ),
        );
      },
      placeholder: (context, url) => _buildPlaceholder(),
      errorWidget: (context, url, error) => _buildErrorWidget(),
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
      maxWidthDiskCache: maxWidthDiskCache,
      maxHeightDiskCache: maxHeightDiskCache,
      key: ValueKey(imageUrl),
    );
  }

  Future<void> _preloadNextImages() async {
    final recentlyViewed = await _getRecentlyViewedUrls();
    // Preload next few images that aren't cached yet
    for (var i = 0; i < 5 && i < recentlyViewed.length; i++) {
      await _ensureImageCached(recentlyViewed[i]);
    }
  }

  // Build placeholder widget
  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }

  // Build error widget
  Widget _buildErrorWidget() {
    return Container(
      color: Colors.grey[200],
      child: const Icon(Icons.book),
    );
  }

  // Clear cache manually if needed
  Future<void> clearCache() async {
    try {
      await _cacheManager.emptyCache();
      PaintingBinding.instance.imageCache.clear();
      
      // Also clear the disk cache folder
      final cacheDir = await getTemporaryDirectory();
      final cacheFolder = Directory('${cacheDir.path}/libCachedImageData');
      if (cacheFolder.existsSync()) {
        await cacheFolder.delete(recursive: true);
      }
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }

  // Get current cache size in bytes
  Future<int> getCacheSize() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final cacheFolder = Directory('${cacheDir.path}/libCachedImageData');
      
      if (!cacheFolder.existsSync()) return 0;
      
      int totalSize = 0;
      await for (final file in cacheFolder.list(recursive: true, followLinks: false)) {
        if (file is File) {
          totalSize += await file.length();
        }
      }
      return totalSize;
    } catch (e) {
      debugPrint('Error calculating cache size: $e');
      return 0;
    }
  }

  // Get maximum cache size
  int getMaxCacheSize() {
    return PaintingBinding.instance.imageCache.maximumSizeBytes;
  }

  // Set maximum cache size (in MB)
  void setMaxCacheSize(int megabytes) {
    final bytes = megabytes * 1024 * 1024;
    PaintingBinding.instance.imageCache.maximumSizeBytes = bytes;
  }
} 