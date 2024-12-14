import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/booking.dart';
import '../constants/booking_constants.dart';

class BookingActions extends StatelessWidget {
  final Booking booking;
  final bool isAdmin;
  final bool isMobile;
  final Function(String, String) onStatusChange;
  final Function(String) onDelete;

  const BookingActions({
    super.key,
    required this.booking,
    required this.isAdmin,
    required this.isMobile,
    required this.onStatusChange,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (!isAdmin) return const SizedBox.shrink();
    
    return isMobile 
      ? _buildMobileActions(context)
      : _buildDesktopActions(context);
  }

  Widget _buildDesktopActions(BuildContext context) {
    if (!isAdmin || booking.id == null) return const SizedBox.shrink();

    final isOverdue = booking.isOverdue;
    final currentStatus = booking.currentStatus;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (currentStatus != 'borrowed' && currentStatus != 'returned')
          _buildIconButton(
            context: context,
            icon: Icons.check_circle_outline,
            onPressed: () => onStatusChange(booking.id!, 'borrowed'),
            tooltip: 'Accept',
            color: AppTheme.bookingStatus['borrowed'],
          ),
        if (currentStatus == 'borrowed' || currentStatus == 'overdue')
          _buildIconButton(
            context: context,
            icon: Icons.assignment_return_outlined,
            onPressed: () => onStatusChange(booking.id!, 'returned'),
            tooltip: 'Return',
            color: AppTheme.bookingStatus['returned'],
          ),
        _buildIconButton(
          context: context,
          icon: Icons.delete_outline,
          onPressed: () => onDelete(booking.id!),
          tooltip: 'Delete',
          color: Colors.red,
        ),
      ],
    );
  }

  Widget _buildMobileActions(BuildContext context) {
    if (!isAdmin || booking.id == null) return const SizedBox.shrink();

    final isOverdue = booking.isOverdue;
    final currentStatus = booking.currentStatus;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppTheme.spacingSmall),
      child: Row(
        children: [
          if (currentStatus != 'borrowed' && currentStatus != 'returned')
            Expanded(
              child: _buildActionButton(
                context: context,
                icon: Icons.check_circle_outline,
                label: 'Approve',
                onPressed: () => onStatusChange(booking.id!, 'borrowed'),
                backgroundColor: AppTheme.bookingStatus['borrowed']!,
              ),
            )
          else if (currentStatus == 'borrowed' || currentStatus == 'overdue')
            Expanded(
              child: _buildActionButton(
                context: context,
                icon: Icons.assignment_return_outlined,
                label: 'Return',
                onPressed: () => onStatusChange(booking.id!, 'returned'),
                backgroundColor: AppTheme.bookingStatus['returned']!,
              ),
            ),
          SizedBox(width: AppTheme.spacingSmall),
          Expanded(
            child: _buildActionButton(
              context: context,
              icon: Icons.delete_outline,
              label: 'Remove',
              onPressed: () => onDelete(booking.id!),
              backgroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    Color? color,
  }) {
    return IconButton(
      icon: Icon(
        icon,
        color: color,
        size: AppTheme.fontSizeLarge + 4,
      ),
      onPressed: onPressed,
      tooltip: tooltip,
      splashRadius: AppTheme.fontSizeLarge + 8,
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color backgroundColor,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(
        icon,
        size: AppTheme.fontSizeLarge,
      ),
      label: Text(
        label,
        style: TextStyle(
          fontSize: AppTheme.fontSizeMedium,
          fontWeight: FontWeight.w500,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(
          vertical: AppTheme.spacingMedium,
          horizontal: AppTheme.spacingMedium,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        ),
      ),
    );
  }
} 