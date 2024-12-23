import 'package:flutter/material.dart';
import '../../models/book.dart';

class BookImage extends StatelessWidget {
  final Book book;

  const BookImage({
    super.key,
    required this.book,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 400),
      child: Image.network(
        book.coverUrl,
        cacheWidth: 400,
        cacheHeight: 600,
        filterQuality: FilterQuality.medium,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
} 