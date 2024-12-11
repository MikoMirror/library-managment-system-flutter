import 'package:flutter/material.dart';
import '../models/booking.dart';
import '../../../core/theme/app_theme.dart';

class BookingCard extends StatelessWidget {
  final Booking booking;
  final bool isAdmin;
  final Function(String, String) onStatusChange;
  final Function(String)? onDelete;

  const BookingCard({
    super.key,
    required this.booking,
    required this.isAdmin,
    required this.onStatusChange,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(8),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    booking.bookTitle ?? 'Loading...',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: isSmallScreen ? 14 : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildStatusChip(context),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 16,
                  color: isDarkMode ? AppTheme.accentDark : AppTheme.accentLight,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${booking.userName ?? 'Loading...'} (${booking.userLibraryNumber ?? 'N/A'})',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: isSmallScreen ? 12 : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.date_range,
                  size: 16,
                  color: isDarkMode ? AppTheme.accentDark : AppTheme.accentLight,
                ),
                const SizedBox(width: 4),
                Text(
                  'Borrowed: ${booking.formattedBorrowedDate}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: isSmallScreen ? 12 : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: isDarkMode ? AppTheme.accentDark : AppTheme.accentLight,
                ),
                const SizedBox(width: 4),
                Text(
                  'Due: ${booking.formattedDueDate}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: booking.isOverdue ? Colors.red : null,
                    fontSize: isSmallScreen ? 12 : null,
                  ),
                ),
              ],
            ),
            if (isAdmin && isSmallScreen) ...[
              const SizedBox(height: 8),
              _buildMobileActionButtons(context),
            ] else if (isAdmin) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildActionButtons(context, isSmallScreen),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMobileActionButtons(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (booking.status == 'pending') {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => onStatusChange(booking.id!, 'borrowed'),
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Apply'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDarkMode ? AppTheme.accentDark : Colors.green,
                foregroundColor: isDarkMode ? AppTheme.primaryDark : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => onDelete?.call(booking.id!),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Remove'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
      );
    } else if (booking.status == 'borrowed') {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => onStatusChange(booking.id!, 'returned'),
              icon: const Icon(Icons.assignment_return_outlined),
              label: const Text('Return'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDarkMode ? AppTheme.accentDark : AppTheme.primaryLight,
                foregroundColor: isDarkMode ? AppTheme.primaryDark : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => onDelete?.call(booking.id!),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Remove'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
      );
    } else {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => onDelete?.call(booking.id!),
          icon: const Icon(Icons.delete_outline),
          label: const Text('Remove'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
          ),
        ),
      );
    }
  }

  Widget _buildActionButtons(BuildContext context, bool isSmallScreen) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final buttonSize = isSmallScreen ? 40.0 : 32.0;
    final iconSize = isSmallScreen ? 24.0 : 20.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (booking.status == 'pending')
          SizedBox(
            width: buttonSize,
            height: buttonSize,
            child: IconButton(
              icon: Icon(
                Icons.check_circle_outline,
                color: isDarkMode ? AppTheme.accentDark : Colors.green,
                size: iconSize,
              ),
              tooltip: 'Approve',
              onPressed: () => onStatusChange(booking.id!, 'borrowed'),
              padding: EdgeInsets.zero,
            ),
          ),
        if (booking.status == 'borrowed')
          SizedBox(
            width: buttonSize,
            height: buttonSize,
            child: IconButton(
              icon: Icon(
                Icons.assignment_return_outlined,
                color: isDarkMode ? AppTheme.accentDark : AppTheme.primaryLight,
                size: iconSize,
              ),
              tooltip: 'Return',
              onPressed: () => onStatusChange(booking.id!, 'returned'),
              padding: EdgeInsets.zero,
            ),
          ),
        SizedBox(
          width: buttonSize,
          height: buttonSize,
          child: IconButton(
            icon: Icon(
              Icons.delete_outline,
              color: Colors.red,
              size: iconSize,
            ),
            tooltip: 'Delete',
            onPressed: () => onDelete?.call(booking.id!),
            padding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    
    final colors = {
      'pending': Colors.orange,
      'borrowed': isDarkMode ? AppTheme.accentDark : AppTheme.primaryLight,
      'returned': Colors.green,
      'rejected': Colors.red,
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 6 : 8,
        vertical: isSmallScreen ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: colors[booking.status]?.withOpacity(0.8) ?? Colors.grey,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        booking.status.substring(0, 1).toUpperCase() + booking.status.substring(1),
        style: TextStyle(
          color: booking.status == 'borrowed'
              ? (isDarkMode ? AppTheme.primaryDark : Colors.black87)
              : Colors.white,
          fontSize: isSmallScreen ? 11 : 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
} 