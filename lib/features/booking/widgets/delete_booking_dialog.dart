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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      title: const Center(
        child: Text(
          'Delete Booking',
          style: TextStyle(
            fontSize: AppTheme.fontSizeLarge,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      content: Text(
        'Delete booking for "$bookTitle"?',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: AppTheme.fontSizeMedium,
          color: isDarkMode ? Colors.white70 : Colors.black87,
        ),
      ),
      contentPadding: EdgeInsets.all(AppTheme.spacingMedium),
      actions: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppTheme.spacingMedium,
            vertical: AppTheme.spacingSmall,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'No',
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeMedium,
                    color: isDarkMode ? AppTheme.accentDark : AppTheme.accentLight,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: Text(
                  'Yes, Delete',
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeMedium,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
} 