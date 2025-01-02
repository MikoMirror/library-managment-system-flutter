import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/reservation_filter_cubit.dart';
import '../../../core/theme/app_theme.dart';

class ReservationFilterSection extends StatelessWidget {
  const ReservationFilterSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isMobileView = MediaQuery.of(context).size.width < 800;
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: isMobileView ? 8 : 18,
      ),
      decoration: BoxDecoration(
        color: isDarkMode 
            ? AppTheme.dark.primary.withAlpha(25)
            : AppTheme.light.primary.withAlpha(25),
        border: Border(
          bottom: BorderSide(
            color: isDarkMode
                ? AppTheme.dark.primary.withAlpha(25)
                : AppTheme.light.primary.withAlpha(51),
          ),
        ),
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: isMobileView
              ? _buildDropdownFilter(context, isDarkMode)
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: ReservationFilter.values.map((filter) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _buildFilterChip(context, filter, isDarkMode),
                    );
                  }).toList(),
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
          padding: const EdgeInsets.symmetric(horizontal: 4),
          labelPadding: const EdgeInsets.symmetric(horizontal: 4),
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getIconForFilter(filter),
                size: 18,
                color: isSelected
                    ? Colors.white
                    : isDarkMode 
                        ? AppTheme.dark.secondary 
                        : AppTheme.light.secondary,
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
              ? AppTheme.dark.surface 
              : AppTheme.light.surface,
          selectedColor: isDarkMode 
              ? AppTheme.dark.primary 
              : AppTheme.light.primary,
          checkmarkColor: Colors.white,
          labelStyle: TextStyle(
            color: isSelected
                ? Colors.white
                : isDarkMode 
                    ? AppTheme.dark.secondary 
                    : AppTheme.light.secondary,
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
                  ? AppTheme.dark.secondary.withAlpha(51)
                  : AppTheme.light.primary.withAlpha(51),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<ReservationFilter>(
              value: currentFilter,
              isExpanded: true,
              icon: Icon(
                Icons.filter_list,
                color: isDarkMode ? AppTheme.dark.secondary : AppTheme.light.secondary,
              ),
              items: ReservationFilter.values.map((filter) {
                return DropdownMenuItem<ReservationFilter>(
                  value: filter,
                  child: Row(
                    children: [
                      Icon(
                        _getIconForFilter(filter),
                        size: 20,
                        color: isDarkMode ? AppTheme.dark.secondary : AppTheme.light.secondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        filter.displayName,
                        style: TextStyle(
                          color: isDarkMode ? AppTheme.dark.secondary : AppTheme.light.secondary,
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
      case ReservationFilter.expired:
        return Icons.timer_off;
      case ReservationFilter.canceled:
        return Icons.cancel_outlined;
    }
  }
}