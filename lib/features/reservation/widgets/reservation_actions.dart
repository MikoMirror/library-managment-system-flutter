import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/reservation.dart';
import '../constants/reservation_constants.dart';

class ReservationActions extends StatelessWidget {
  final Reservation reservation;
  final bool isAdmin;
  final bool isMobile;
  final Function(String, String) onStatusChange;
  final Function(String) onDelete;

  const ReservationActions({
    super.key,
    required this.reservation,
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
    if (!isAdmin || reservation.id == null) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final coreColors = isDark ? AppTheme.dark : AppTheme.light;
    final currentStatus = reservation.currentStatus;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (currentStatus != 'borrowed' && currentStatus != 'returned')
          _buildIconButton(
            context: context,
            icon: Icons.check_circle_outline,
            onPressed: () => onStatusChange(reservation.id!, 'borrowed'),
            tooltip: 'Accept',
            color: coreColors.success,
          ),
        if (currentStatus == 'borrowed' || currentStatus == 'overdue')
          _buildIconButton(
            context: context,
            icon: Icons.assignment_return_outlined,
            onPressed: () => onStatusChange(reservation.id!, 'returned'),
            tooltip: 'Return',
            color: coreColors.info,
          ),
        _buildIconButton(
          context: context,
          icon: Icons.delete_outline,
          onPressed: () => onDelete(reservation.id!),
          tooltip: 'Delete',
          color: coreColors.error,
        ),
      ],
    );
  }

  Widget _buildMobileActions(BuildContext context) {
    if (!isAdmin || reservation.id == null) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final coreColors = isDark ? AppTheme.dark : AppTheme.light;
    final currentStatus = reservation.currentStatus;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          if (currentStatus != 'borrowed' && currentStatus != 'returned')
            Expanded(
              child: _buildActionButton(
                context: context,
                icon: Icons.check_circle_outline,
                label: 'Approve',
                onPressed: () => onStatusChange(reservation.id!, 'borrowed'),
                backgroundColor: coreColors.success,
              ),
            )
          else if (currentStatus == 'borrowed' || currentStatus == 'overdue')
            Expanded(
              child: _buildActionButton(
                context: context,
                icon: Icons.assignment_return_outlined,
                label: 'Return',
                onPressed: () => onStatusChange(reservation.id!, 'returned'),
                backgroundColor: coreColors.info,
              ),
            ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildActionButton(
              context: context,
              icon: Icons.delete_outline,
              label: 'Remove',
              onPressed: () => onDelete(reservation.id!),
              backgroundColor: coreColors.error,
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
        size: 24,
      ),
      onPressed: onPressed,
      tooltip: tooltip,
      splashRadius: 24,
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color backgroundColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final coreColors = isDark ? AppTheme.dark : AppTheme.light;

    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(
        icon,
        size: 20,
      ),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: coreColors.onPrimary,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: coreColors.onPrimary,
        padding: const EdgeInsets.symmetric(
          vertical: 12.0,
          horizontal: 12.0,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
    );
  }
} 