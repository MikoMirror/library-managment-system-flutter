import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/book.dart';

class BookDetailsCard extends StatelessWidget {
  final Book book;

  const BookDetailsCard({
    super.key,
    required this.book,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Book Details',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildDetailRow('ISBN:', book.isbn),
            _buildDetailRow('Categories:', book.categories),
            _buildDetailRow('Page Count:', book.pageCount.toString()),
            _buildDetailRow(
              'Published Date:',
              book.publishedDate != null
                  ? DateFormat('yyyy-MM-dd').format(book.publishedDate!.toDate())
                  : 'N/A',
            ),
            _buildDetailRow('Available Copies:', book.booksQuantity.toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
} 