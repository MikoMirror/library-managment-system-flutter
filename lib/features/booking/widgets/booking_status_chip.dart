import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/booking.dart';

class BookingStatusChip extends StatelessWidget {
  final Booking booking;
  final bool isSmallScreen;
  final bool isDarkMode;

  const BookingStatusChip({
    super.key,
    required this.booking,
    this.isSmallScreen = false,
    this.isDarkMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final currentStatus = booking.currentStatus;
    final statusColor = AppTheme.getStatusColor(currentStatus);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? AppTheme.spacingSmall : AppTheme.spacingMedium,
        vertical: isSmallScreen ? AppTheme.spacingXSmall : AppTheme.spacingSmall,
      ),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.8),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
      ),
      child: Text(
        currentStatus.toUpperCase(),
        style: TextStyle(
          color: Colors.white,
          fontSize: isSmallScreen ? AppTheme.fontSizeSmall : AppTheme.fontSizeMedium,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
} 