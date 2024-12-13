import 'package:flutter/material.dart';

class DeleteBookingDialog extends StatelessWidget {
  final String bookTitle;

  const DeleteBookingDialog({
    super.key,
    required this.bookTitle,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete Booking'),
      content: Text('Are you sure you want to delete the booking for "$bookTitle"?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('No'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(
            foregroundColor: Colors.red,
          ),
          child: const Text('Yes, Delete'),
        ),
      ],
    );
  }
} 