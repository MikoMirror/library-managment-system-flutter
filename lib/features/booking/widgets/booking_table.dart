import 'package:flutter/material.dart';
import '../models/booking.dart';
import 'booking_card.dart';
import '../../../core/theme/app_theme.dart';

class BookingTable extends StatelessWidget {
  final List<Booking> bookings;
  final bool isAdmin;
  final Function(String, String) onStatusChange;
  final Function(String)? onDelete;

  const BookingTable({
    super.key,
    required this.bookings,
    required this.isAdmin,
    required this.onStatusChange,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = _calculateCrossAxisCount(constraints.maxWidth);
        final isSmallScreen = constraints.maxWidth < 600;
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        
        return Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: isDarkMode 
                ? AppTheme.primaryDark.withOpacity(0.05)
                : AppTheme.primaryLight.withOpacity(0.05),
          ),
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: isSmallScreen ? 2.2 : 1.6,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              return BookingCard(
                booking: bookings[index],
                isAdmin: isAdmin,
                onStatusChange: onStatusChange,
                onDelete: onDelete,
              );
            },
          ),
        );
      },
    );
  }

  int _calculateCrossAxisCount(double width) {
    if (width < 600) return 1;
    if (width < 900) return 2;
    if (width < 1200) return 3;
    return 4;
  }
} 