import 'package:flutter/material.dart';
import '../models/booking.dart';
import 'booking_card.dart';

class BookingTable extends StatelessWidget {
  final List<Booking> bookings;
  final bool isAdmin;
  final Function(String, String) onStatusChange;

  const BookingTable({
    super.key,
    required this.bookings,
    required this.isAdmin,
    required this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = _calculateCrossAxisCount(constraints.maxWidth);
        final isSmallScreen = constraints.maxWidth < 600;
        
        return Padding(
          padding: const EdgeInsets.all(16.0),
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