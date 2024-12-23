import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/reservation_filter_cubit.dart';
import '../../../core/theme/app_theme.dart';

class ReservationFilterButton extends StatelessWidget {
  final String label;
  final ReservationFilter filter;
  final IconData icon;

  const ReservationFilterButton({
    super.key,
    required this.label,
    required this.filter,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return BlocBuilder<ReservationFilterCubit, ReservationFilter>(
      builder: (context, currentFilter) {
        final isSelected = currentFilter == filter;
        return ElevatedButton.icon(
          onPressed: () {
            context.read<ReservationFilterCubit>().updateFilter(filter);
          },
          icon: Icon(
            icon,
            color: isSelected
                ? (isDarkMode ? Colors.white : Colors.white)
                : (isDarkMode ? AppTheme.dark.secondary : AppTheme.light.secondary),
          ),
          label: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? (isDarkMode ? Colors.white : Colors.white)
                  : (isDarkMode ? AppTheme.dark.secondary : AppTheme.light.secondary),
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected
                ? (isDarkMode ? AppTheme.dark.primary : AppTheme.light.primary)
                : Theme.of(context).cardColor,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            elevation: isSelected ? 2 : 1,
          ),
        );
      },
    );
  }
} 