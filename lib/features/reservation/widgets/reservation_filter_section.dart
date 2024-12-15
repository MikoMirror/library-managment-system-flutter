import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/reservation_filter_cubit.dart';
import '../../../core/theme/app_theme.dart';

class ReservationFilterSection extends StatelessWidget {
  const ReservationFilterSection({super.key});

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
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: isSmallScreen
              ? _buildDropdownFilter(context, isDarkMode)
              : Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 12,
                    children: ReservationFilter.values.map((filter) {
                      return _buildFilterChip(context, filter, isDarkMode);
                    }).toList(),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, ReservationFilter filter, bool isDarkMode) {
    return BlocBuilder<ReservationFilterCubit, ReservationFilter>(
      builder: (context, currentFilter) {
        final isSelected = currentFilter == filter;
        
        return FilterChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getIconForFilter(filter),
                size: 18,
                color: isSelected
                    ? Colors.white
                    : isDarkMode 
                        ? AppTheme.accentDark 
                        : AppTheme.accentLight,
              ),
              const SizedBox(width: 8),
              Text(filter.displayName),
            ],
          ),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              context.read<ReservationFilterCubit>().updateFilter(filter);
            }
          },
          backgroundColor: isDarkMode 
              ? AppTheme.surfaceDark 
              : AppTheme.surfaceLight,
          selectedColor: isDarkMode 
              ? AppTheme.primaryDark 
              : AppTheme.primaryLight,
          checkmarkColor: Colors.white,
          labelStyle: TextStyle(
            color: isSelected
                ? Colors.white
                : isDarkMode 
                    ? AppTheme.textDark 
                    : AppTheme.textLight,
          ),
        );
      },
    );
  }

  Widget _buildDropdownFilter(BuildContext context, bool isDarkMode) {
    return BlocBuilder<ReservationFilterCubit, ReservationFilter>(
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
            child: DropdownButton<ReservationFilter>(
              value: currentFilter,
              isExpanded: true,
              icon: Icon(
                Icons.filter_list,
                color: isDarkMode ? AppTheme.accentDark : AppTheme.accentLight,
              ),
              items: ReservationFilter.values.map((filter) {
                return DropdownMenuItem<ReservationFilter>(
                  value: filter,
                  child: Row(
                    children: [
                      Icon(
                        _getIconForFilter(filter),
                        size: 20,
                        color: isDarkMode ? AppTheme.accentDark : AppTheme.accentLight,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        filter.displayName,
                        style: TextStyle(
                          color: isDarkMode ? AppTheme.accentDark : AppTheme.accentLight,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (ReservationFilter? newFilter) {
                if (newFilter != null) {
                  context.read<ReservationFilterCubit>().updateFilter(newFilter);
                }
              },
            ),
          ),
        );
      },
    );
  }

  IconData _getIconForFilter(ReservationFilter filter) {
    switch (filter) {
      case ReservationFilter.all:
        return Icons.list;
      case ReservationFilter.reserved:
        return Icons.pending;
      case ReservationFilter.borrowed:
        return Icons.book;
      case ReservationFilter.overdue:
        return Icons.warning_amber_rounded;
      case ReservationFilter.returned:
        return Icons.assignment_returned;
    }
  }
}