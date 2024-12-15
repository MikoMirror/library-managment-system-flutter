import 'package:flutter/material.dart';
import '../utils/book_cover_utils.dart';

enum CoverSource {
  google,
  openLibrary,
}

class BookCoverSelector extends StatefulWidget {
  final String? initialUrl;
  final String isbn;
  final Function(String) onCoverSelected;
  final VoidCallback? onImageLoaded;

  const BookCoverSelector({
    super.key,
    this.initialUrl,
    required this.isbn,
    required this.onCoverSelected,
    this.onImageLoaded,
  });

  @override
  State<BookCoverSelector> createState() => _BookCoverSelectorState();
}

class _BookCoverSelectorState extends State<BookCoverSelector> {
  CoverSource _selectedSource = CoverSource.openLibrary;
  String? _selectedUrl;
  bool _isLoading = false;
  CoverSize _selectedSize = CoverSize.large;

  @override
  void initState() {
    super.initState();
    // Load initial cover immediately if ISBN is available
    if (widget.isbn.isNotEmpty) {
      _selectedUrl = BookCoverUtils.getOpenLibraryCover(
        widget.isbn,
        size: CoverSize.large,
      );
      widget.onCoverSelected(_selectedUrl!);
    } else {
      _selectedUrl = widget.initialUrl;
    }
  }

  void _updateCover() {
    String newUrl;
    
    if (_selectedSource == CoverSource.google) {
      newUrl = BookCoverUtils.getGoogleBooksCover(
        widget.isbn,
        zoom: _sizeToZoom(_selectedSize),
      );
    } else {
      newUrl = BookCoverUtils.getOpenLibraryCover(
        widget.isbn,
        size: _selectedSize,
      );
    }
    
    setState(() {
      _selectedUrl = newUrl;
      _isLoading = true;
    });
    widget.onCoverSelected(newUrl);
  }

  int _sizeToZoom(CoverSize size) {
    switch (size) {
      case CoverSize.small: return 1;
      case CoverSize.medium: return 2;
      case CoverSize.large: return 4;
    }
  }

  String _sizeToString(CoverSize size) {
    switch (size) {
      case CoverSize.small: return 'Small';
      case CoverSize.medium: return 'Medium';
      case CoverSize.large: return 'Large';
    }
  }

  Widget _buildCoverPreview() {
    if (_selectedUrl == null) {
      return Container(
        width: 200,
        height: 300,
        color: Colors.grey[300],
        child: const Icon(Icons.image),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        Image.network(
          _selectedUrl!,
          width: 200,
          height: 300,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && _isLoading) {
                  setState(() {
                    _isLoading = false;
                  });
                }
                widget.onImageLoaded?.call();
              });
              return child;
            }
            return const SizedBox(
              width: 200,
              height: 300,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _isLoading) {
                setState(() {
                  _isLoading = false;
                });
              }
            });
            return Container(
              width: 200,
              height: 300,
              color: Colors.grey[300],
              child: const Icon(Icons.error),
            );
          },
        ),
        if (_isLoading)
          Container(
            width: 200,
            height: 300,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }

  String _getUrlWithSize(String url, CoverSize size) {
    if (url.contains('openlibrary.org')) {
      return url.replaceAll(RegExp(r'-[SML]\.jpg'), '-${_sizeToString(size)}.jpg');
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildCoverPreview(),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SegmentedButton<CoverSource>(
              segments: const [
                ButtonSegment<CoverSource>(
                  value: CoverSource.google,
                  label: Text('Google Books'),
                ),
                ButtonSegment<CoverSource>(
                  value: CoverSource.openLibrary,
                  label: Text('Open Library'),
                ),
              ],
              selected: {_selectedSource},
              onSelectionChanged: (Set<CoverSource> newSelection) {
                setState(() {
                  _selectedSource = newSelection.first;
                  _isLoading = true;
                });
                _updateCover();
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        SegmentedButton<CoverSize>(
          segments: const [
            ButtonSegment<CoverSize>(
              value: CoverSize.small,
              label: Text('Small'),
            ),
            ButtonSegment<CoverSize>(
              value: CoverSize.medium,
              label: Text('Medium'),
            ),
            ButtonSegment<CoverSize>(
              value: CoverSize.large,
              label: Text('Large'),
            ),
          ],
          selected: {_selectedSize},
          onSelectionChanged: (Set<CoverSize> newSelection) {
            setState(() {
              _selectedSize = newSelection.first;
              _isLoading = true;
            });
            _updateCover();
          },
        ),
      ],
    );
  }
} 