import 'package:flutter/material.dart';
import '../../models/book.dart';

class BookHeader extends StatelessWidget {
  final Book book;

  const BookHeader({
    super.key,
    required this.book,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          book.title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'by ${book.author}',
          style: theme.textTheme.titleMedium,
        ),
      ],
    );
  }
} 