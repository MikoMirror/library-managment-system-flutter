import 'package:flutter/material.dart';
import '../screens/book_form_screen.dart';
import '../../../core/services/api/google_books_service.dart';
import 'dart:async';

class AddBookDialog extends StatefulWidget {
  const AddBookDialog({super.key});

  @override
  State<AddBookDialog> createState() => _AddBookDialogState();
}

class _AddBookDialogState extends State<AddBookDialog> {
  final TextEditingController _isbnController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _isbnController.dispose();
    super.dispose();
  }

  Future<void> _searchBook() async {
    final isbn = _isbnController.text.trim();
    if (isbn.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an ISBN')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final book = await GoogleBooksService.findBookByIsbn(isbn);
      
      if (!mounted) return;
      
      if (book != null) {
        Navigator.of(context).pop();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookFormScreen(
              collectionId: 'books',
              mode: FormMode.add,
              book: book,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Book not found')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: 400,
        maxHeight: 500,
      ),
      child: AlertDialog(
        title: const Text('Add Book'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Choose how to add a book:'),
            const SizedBox(height: 16),
            TextField(
              controller: _isbnController,
              decoration: const InputDecoration(
                labelText: 'ISBN',
                hintText: 'Enter ISBN number',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : _searchBook,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Find Book'),
            ),
            const SizedBox(height: 16),
            const Text('OR'),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BookFormScreen(
                      collectionId: 'books',
                      mode: FormMode.add,
                    ),
                  ),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).primaryColor,
              ),
              child: const Text('Add Manually'),
            ),
          ],
        ),
      ),
    );
  }
} 