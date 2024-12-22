import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/reservation.dart';

class ReservationStatusChip extends StatelessWidget {
  final Reservation reservation;
  final bool isSmallScreen;
  final bool isDarkMode;

  const ReservationStatusChip({
    super.key,
    required this.reservation,
    this.isSmallScreen = false,
    this.isDarkMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final currentStatus = reservation.status;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final coreColors = isDark ? AppTheme.dark : AppTheme.light;
    
    Color getStatusColor() {
      switch (currentStatus.toLowerCase()) {
        case 'pending': return coreColors.warning;
        case 'borrowed': return coreColors.success;
        case 'returned': return coreColors.info;
        case 'overdue': return coreColors.error;
        case 'expired': return coreColors.expired;
        default: return coreColors.primary;
      }
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 8.0 : 12.0,
        vertical: isSmallScreen ? 4.0 : 8.0,
      ),
      decoration: BoxDecoration(
        color: getStatusColor().withOpacity(0.8),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Text(
        currentStatus.toUpperCase(),
        style: TextStyle(
          color: coreColors.onPrimary,
          fontSize: isSmallScreen ? 12.0 : 14.0,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
} 