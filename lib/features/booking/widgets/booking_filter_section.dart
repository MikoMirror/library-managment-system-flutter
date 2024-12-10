import 'package:flutter/material.dart';
import '../cubit/booking_filter_cubit.dart';
import '../../../core/theme/app_theme.dart';
import 'booking_filter_button.dart';

class BookingFilterSection extends StatelessWidget {
  const BookingFilterSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppTheme.primaryDark.withOpacity(0.1)
            : AppTheme.primaryLight.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppTheme.primaryDark.withOpacity(0.1)
                : AppTheme.primaryLight.withOpacity(0.2),
          ),
        ),
      ),
      child: Center(
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            BookingFilterButton(
              label: 'All',
              filter: BookingFilter.all,
              icon: Icons.list,
            ),
            BookingFilterButton(
              label: 'Pending',
              filter: BookingFilter.pending,
              icon: Icons.pending,
            ),
            BookingFilterButton(
              label: 'Borrowed',
              filter: BookingFilter.borrowed,
              icon: Icons.book,
            ),
            BookingFilterButton(
              label: 'Returned',
              filter: BookingFilter.returned,
              icon: Icons.assignment_returned,
            ),
          ],
        ),
      ),
    );
  }
} 