import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class DeleteBookingDialog extends StatelessWidget {
  final String bookTitle;

  const DeleteBookingDialog({
    super.key,
    required this.bookTitle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final coreColors = isDark ? AppTheme.dark : AppTheme.light;

    return AlertDialog(
      title: Center(
        child: Text(
          'Delete Booking',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: coreColors.onSurface,
          ),
        ),
      ),
      content: Text(
        'Delete booking for "$bookTitle"?',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16,
          color: coreColors.textSubtle,
        ),
      ),
      contentPadding: const EdgeInsets.all(16.0),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'No',
            style: TextStyle(
              fontSize: 16,
              color: coreColors.secondary,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(
            foregroundColor: coreColors.error,
          ),
          child: const Text(
            'Yes, Delete',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }
} 