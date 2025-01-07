import 'package:flutter/material.dart';
import '../screens/book_form_screen.dart';
import '../../../core/services/api/google_books_service.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../widgets/scanner/barcode_scanner_view.dart';

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

  Future<void> _startBarcodeScanner() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BarcodeScannerView(
          onBarcodeDetected: (barcode) {
            _isbnController.text = barcode;
            _searchBook();
          },
        ),
      ),
    );

    if (result != null) {
      _isbnController.text = result;
      await _searchBook();
    }
  }

  bool get _isMobileDevice {
    return !kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS || 
        defaultTargetPlatform == TargetPlatform.android);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 400,
          maxHeight: 500,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Add Book',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Text(
                'Find book by ISBN',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _isbnController,
                      decoration: InputDecoration(
                        labelText: 'ISBN',
                        hintText: 'Enter ISBN number',
                        border: const OutlineInputBorder(),
                        suffixIcon: _isMobileDevice ? IconButton(
                          icon: const Icon(Icons.qr_code_scanner),
                          onPressed: _isLoading ? null : _startBarcodeScanner,
                          tooltip: 'Scan ISBN',
                        ) : null,
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _searchBook,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Find Book'),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Divider(
                      color: theme.dividerColor,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'OR',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      color: theme.dividerColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              OutlinedButton(
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
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Add Book Manually'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 