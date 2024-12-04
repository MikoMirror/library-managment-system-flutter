import 'package:flutter/material.dart';
import '../models/book.dart';

class BookImageWidget extends StatelessWidget {
  final Book book;
  final bool isDetailView;
  final double? maxHeight;

  const BookImageWidget({
    super.key,
    required this.book,
    this.isDetailView = false,
    this.maxHeight,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate the maximum height based on screen size
        final screenHeight = MediaQuery.of(context).size.height;
        final defaultMaxHeight = isDetailView ? screenHeight * 0.4 : screenHeight * 0.25;
        
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: maxHeight ?? defaultMaxHeight,
            maxWidth: isDetailView ? 350 : 250,
          ),
          child: AspectRatio(
            aspectRatio: 0.7, // Standard book cover ratio
            child: Image.network(
              _getHighResImageUrl(),
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded / 
                          loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.book, size: 40),
                );
              },
            ),
          ),
        );
      },
    );
  }

  String _getHighResImageUrl() {
    if (book.externalImageUrl != null && book.externalImageUrl!.isNotEmpty) {
      if (book.externalImageUrl!.contains('googleusercontent.com')) {
        return book.externalImageUrl!.replaceAll('zoom=1', 'zoom=3');
      }
      return book.externalImageUrl!;
    }
    return 'https://via.placeholder.com/128x192.png?text=No+Cover';
  }
} 