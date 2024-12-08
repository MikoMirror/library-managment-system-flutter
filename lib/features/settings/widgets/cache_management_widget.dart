import 'package:flutter/material.dart';
import '../../../core/services/image/image_cache_service.dart';

class CacheManagementWidget extends StatefulWidget {
  const CacheManagementWidget({super.key});

  @override
  State<CacheManagementWidget> createState() => _CacheManagementWidgetState();
}

class _CacheManagementWidgetState extends State<CacheManagementWidget> {
  final ImageCacheService _imageCacheService = ImageCacheService();
  
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.storage_outlined, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Cache Management',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.help_outline),
                  onPressed: () => _showCacheInfo(context),
                  tooltip: 'Cache Information',
                ),
              ],
            ),
            const Divider(height: 24),
            
            // Cache Size Information
            FutureBuilder<int>(
              future: _imageCacheService.getCacheSize(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final cacheSize = snapshot.data ?? 0;
                final cacheSizeMB = (cacheSize / (1024 * 1024)).toStringAsFixed(2);
                final maxCacheSizeMB = 
                    (_imageCacheService.getMaxCacheSize() / (1024 * 1024)).toStringAsFixed(2);
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCacheSizeInfo(cacheSizeMB, maxCacheSizeMB),
                    const SizedBox(height: 24),
                    _buildCacheSizeSlider(),
                    const SizedBox(height: 16),
                    _buildClearCacheButton(),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCacheSizeInfo(String currentSize, String maxSize) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current Cache Usage',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: double.parse(currentSize) / double.parse(maxSize),
            backgroundColor: Colors.grey[300],
          ),
          const SizedBox(height: 8),
          Text(
            '$currentSize MB of $maxSize MB used',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildCacheSizeSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Maximum Cache Size',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        StatefulBuilder(
          builder: (context, setState) {
            final currentMaxSize = 
                _imageCacheService.getMaxCacheSize() / (1024 * 1024);
            
            return Column(
              children: [
                Slider(
                  value: currentMaxSize,
                  min: 50,
                  max: 500,
                  divisions: 9,
                  label: '${currentMaxSize.round()} MB',
                  onChanged: (value) {
                    setState(() {
                      _imageCacheService.setMaxCacheSize(value.round());
                    });
                  },
                ),
                Text(
                  '${currentMaxSize.round()} MB',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildClearCacheButton() {
    return Center(
      child: OutlinedButton.icon(
        onPressed: _showClearCacheDialog,
        icon: const Icon(Icons.delete_outline),
        label: const Text('Clear Cache'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Future<void> _showClearCacheDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
          'Are you sure you want to clear all cached images? '
          'This will free up space but images will need to be '
          'downloaded again when viewed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _imageCacheService.clearCache();
      setState(() {}); // Refresh the widget
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cache cleared successfully'),
          ),
        );
      }
    }
  }

  void _showCacheInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Cache'),
        content: const SingleChildScrollView(
          child: Text(
            'Cache is temporary storage that helps load images faster and reduces '
            'data usage. Images you\'ve viewed are stored locally on your device.\n\n'
            '• Current Cache: Amount of space currently used by cached images\n'
            '• Maximum Cache: Maximum allowed space for storing cached images\n'
            '• Clear Cache: Removes all cached images to free up space',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}