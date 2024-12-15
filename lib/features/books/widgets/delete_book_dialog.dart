import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/book.dart';
import '../../../core/services/database/firestore_service.dart';
import '../../../features/books/bloc/books_bloc.dart';
import '../../../features/books/bloc/books_event.dart';

class DeleteBookDialog extends StatelessWidget {
  final Book book;

  const DeleteBookDialog({
    super.key,
    required this.book,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete Book'),
      content: Text('Are you sure you want to delete "${book.title}"?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            context.read<BooksBloc>().add(DeleteBook(book.id!));
            Navigator.of(context).pop();
          },
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Delete'),
        ),
      ],
    );
  }
} 