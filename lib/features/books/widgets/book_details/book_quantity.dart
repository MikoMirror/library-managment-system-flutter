import 'package:flutter/material.dart';
import '../../models/book.dart';

class BookQuantity extends StatelessWidget {
  final Book book;

  const BookQuantity({
    super.key,
    required this.book,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Books available in library: ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          Text(
            '${book.booksQuantity}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: book.booksQuantity > 0 ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }
} 