import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/booking_filter_cubit.dart';
import '../../../core/theme/app_theme.dart';
import 'booking_filter_button.dart';

class BookingFilterSection extends StatelessWidget {
  const BookingFilterSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode 
            ? AppTheme.primaryDark.withOpacity(0.1)
            : AppTheme.primaryLight.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: isDarkMode
                ? AppTheme.primaryDark.withOpacity(0.1)
                : AppTheme.primaryLight.withOpacity(0.2),
          ),
        ),
      ),
      child: Center(
        child: isSmallScreen
            ? _buildDropdownFilter(context, isDarkMode)
            : const Wrap(
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
                    label: 'Overdue',
                    filter: BookingFilter.overdue,
                    icon: Icons.warning_amber_rounded,
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

  Widget _buildDropdownFilter(BuildContext context, bool isDarkMode) {
    return BlocBuilder<BookingFilterCubit, BookingFilter>(
      builder: (context, currentFilter) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDarkMode 
                  ? AppTheme.accentDark.withOpacity(0.3)
                  : AppTheme.primaryLight.withOpacity(0.3),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<BookingFilter>(
              value: currentFilter,
              isExpanded: true,
              icon: Icon(
                Icons.filter_list,
                color: isDarkMode ? AppTheme.accentDark : AppTheme.accentLight,
              ),
              items: [
                _buildDropdownItem(BookingFilter.all, 'All', Icons.list, isDarkMode),
                _buildDropdownItem(BookingFilter.pending, 'Pending', Icons.pending, isDarkMode),
                _buildDropdownItem(BookingFilter.borrowed, 'Borrowed', Icons.book, isDarkMode),
                _buildDropdownItem(BookingFilter.overdue, 'Overdue', Icons.warning_amber_rounded, isDarkMode),
                _buildDropdownItem(BookingFilter.returned, 'Returned', Icons.assignment_returned, isDarkMode),
              ],
              onChanged: (BookingFilter? newFilter) {
                if (newFilter != null) {
                  context.read<BookingFilterCubit>().updateFilter(newFilter);
                }
              },
            ),
          ),
        );
      },
    );
  }

  DropdownMenuItem<BookingFilter> _buildDropdownItem(
    BookingFilter filter,
    String label,
    IconData icon,
    bool isDarkMode,
  ) {
    return DropdownMenuItem<BookingFilter>(
      value: filter,
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isDarkMode ? AppTheme.accentDark : AppTheme.accentLight,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: isDarkMode ? AppTheme.accentDark : AppTheme.accentLight,
            ),
          ),
        ],
      ),
    );
  }
} 