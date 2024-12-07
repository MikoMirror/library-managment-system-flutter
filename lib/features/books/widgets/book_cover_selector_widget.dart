import 'package:flutter/material.dart';
import '../utils/book_cover_utils.dart';

class BookCoverSelector extends StatefulWidget {
  final String? initialUrl;
  final String isbn;
  final Function(String) onCoverSelected;

  const BookCoverSelector({
    super.key,
    this.initialUrl,
    required this.isbn,
    required this.onCoverSelected,
  });

  @override
  State<BookCoverSelector> createState() => _BookCoverSelectorState();
}

class _BookCoverSelectorState extends State<BookCoverSelector> {
  late String _selectedUrl;
  CoverSize _selectedSize = CoverSize.large;
  CoverSource _selectedSource = CoverSource.google;

  @override
  void initState() {
    super.initState();
    _selectedUrl = widget.initialUrl ?? '';
  }

  void _updateCover() {
    String newUrl = _selectedUrl;
    
    if (_selectedSource == CoverSource.google && _selectedUrl.contains('books.google.com')) {
      newUrl = BookCoverUtils.getGoogleBooksCover(_selectedUrl, zoom: _sizeToZoom(_selectedSize));
    } else if (_selectedSource == CoverSource.openLibrary) {
      newUrl = BookCoverUtils.getOpenLibraryCover(widget.isbn, size: _selectedSize);
    }
    
    widget.onCoverSelected(newUrl);
  }

  int _sizeToZoom(CoverSize size) {
    switch (size) {
      case CoverSize.small: return 1;
      case CoverSize.medium: return 2;
      case CoverSize.large: return 4;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 600;
    String displayUrl = '';
    
    // Determine which URL to display based on selected source
    if (_selectedSource == CoverSource.google) {
      displayUrl = _selectedUrl.contains('books.google.com') 
          ? BookCoverUtils.getGoogleBooksCover(_selectedUrl, zoom: _sizeToZoom(_selectedSize))
          : 'placeholder_url';
    } else {
      displayUrl = BookCoverUtils.getOpenLibraryCover(widget.isbn, size: _selectedSize);
    }
    
    return Column(
      children: [
        // Book Cover Preview
        Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 24.0),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: isDesktop ? 400 : 300,
              maxHeight: isDesktop ? 600 : 450,
            ),
            child: AspectRatio(
              aspectRatio: 3/4,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  displayUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.book, size: 40),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        
        // Source Selection
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SegmentedButton<CoverSource>(
              segments: const [
                ButtonSegment(
                  value: CoverSource.google,
                  label: Text('Google Books'),
                ),
                ButtonSegment(
                  value: CoverSource.openLibrary,
                  label: Text('Open Library'),
                ),
              ],
              selected: {_selectedSource},
              onSelectionChanged: (Set<CoverSource> selection) {
                setState(() {
                  _selectedSource = selection.first;
                  _updateCover();
                });
              },
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Size Selection
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SegmentedButton<CoverSize>(
              segments: const [
                ButtonSegment(
                  value: CoverSize.small,
                  label: Text('Small'),
                ),
                ButtonSegment(
                  value: CoverSize.medium,
                  label: Text('Medium'),
                ),
                ButtonSegment(
                  value: CoverSize.large,
                  label: Text('Large'),
                ),
              ],
              selected: {_selectedSize},
              onSelectionChanged: (Set<CoverSize> selection) {
                setState(() {
                  _selectedSize = selection.first;
                  _updateCover();
                });
              },
            ),
          ],
        ),
      ],
    );
  }
}

enum CoverSource {
  google,
  openLibrary,
} 