import 'package:flutter/material.dart';
import '../../../core/services/image/image_cache_service.dart';
import 'dart:async';

class CacheManagementWidget extends StatefulWidget {
  const CacheManagementWidget({super.key});

  @override
  State<CacheManagementWidget> createState() => _CacheManagementWidgetState();
}

class _CacheManagementWidgetState extends State<CacheManagementWidget> {
  final ImageCacheService _imageCacheService = ImageCacheService();
  final _cacheUpdateController = StreamController<int>.broadcast();
  
  @override
  void dispose() {
    _cacheUpdateController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Check if we're on a mobile device
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.storage_outlined, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Wrap(
                    children: [
                      Text(
                        'Cache ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Management',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.help_outline, size: 20),
                  onPressed: () => _showCacheInfo(context),
                  tooltip: 'Cache Information',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const Divider(height: 16),
            
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
                
                return isMobile 
                    ? _buildMobileLayout(cacheSizeMB, maxCacheSizeMB)
                    : _buildDesktopLayout(cacheSizeMB, maxCacheSizeMB);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout(String currentSize, String maxSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Current Cache Usage',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        StreamBuilder<int>(
          stream: _cacheUpdateController.stream,
          initialData: _imageCacheService.getMaxCacheSize(),
          builder: (context, snapshot) {
            final maxCacheSize = snapshot.data ?? _imageCacheService.getMaxCacheSize();
            return Column(
              children: [
                LinearProgressIndicator(
                  value: double.parse(currentSize) / (maxCacheSize / (1024 * 1024)),
                  backgroundColor: Colors.grey[800],
                  minHeight: 8,
                ),
                const SizedBox(height: 4),
                Text(
                  '$currentSize MB of ${(maxCacheSize / (1024 * 1024)).toStringAsFixed(2)} MB used',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        const Text(
          'Maximum Cache Size',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        StatefulBuilder(
          builder: (context, setState) {
            final currentMaxSize = 
                _imageCacheService.getMaxCacheSize() / (1024 * 1024);
            
            return Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '500 MB',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 200,
                          child: RotatedBox(
                            quarterTurns: 3,
                            child: Slider(
                              value: currentMaxSize,
                              min: 50,
                              max: 500,
                              divisions: 9,
                              label: '${currentMaxSize.round()} MB',
                              onChanged: (value) {
                                setState(() {
                                  _imageCacheService.setMaxCacheSize(value.round());
                                  _cacheUpdateController.add(
                                    _imageCacheService.getMaxCacheSize()
                                  );
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '50 MB',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Column(
                  children: [
                    const Text(
                      'Current Size:',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${currentMaxSize.round()} MB',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: _showClearCacheDialog,
                    icon: const Icon(Icons.delete_outline, size: 20),
                    label: const Text(
                      'Clear Cache',
                      style: TextStyle(fontSize: 16),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(String currentSize, String maxSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
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
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: double.parse(currentSize) / double.parse(maxSize),
                backgroundColor: Colors.grey[300],
                minHeight: 10,
              ),
              const SizedBox(height: 8),
              Text(
                '$currentSize MB of $maxSize MB used',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildCacheSizeSlider(),
        const SizedBox(height: 16),
        Center(
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
        ),
      ],
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