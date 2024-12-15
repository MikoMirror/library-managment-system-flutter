import 'package:flutter/material.dart';
import '../models/reservation.dart';
import '../../../core/theme/app_theme.dart';

class ReservationCard extends StatelessWidget {
  final Reservation reservation;
  final bool isAdmin;
  final Function(String, String) onStatusChange;
  final Function(String)? onDelete;

  const ReservationCard({
    super.key,
    required this.reservation,
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
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExpansionTile(
            title: Row(
              children: [
                Icon(
                  Icons.book_outlined,
                  size: 20,
                  color: isDarkMode ? AppTheme.accentDark : AppTheme.accentLight,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reservation.bookTitle ?? 'Loading...',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: isSmallScreen ? 14 : 16,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (reservation.isOverdue) ...[
                        const SizedBox(height: 4),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.yellow[800],
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                size: 16,
                                color: Colors.black87,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'OVERDUE',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildStatusChip(context),
              ],
            ),
            subtitle: Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 16,
                  color: isDarkMode ? AppTheme.accentDark : AppTheme.accentLight,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${reservation.userName ?? 'Loading...'} (${reservation.userLibraryNumber ?? 'N/A'})',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: isSmallScreen ? 12 : 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(
                      context,
                      'Borrowed',
                      reservation.formattedBorrowedDate,
                      Icons.date_range,
                    ),
                    _buildInfoRow(
                      context,
                      'Due',
                      reservation.formattedDueDate,
                      Icons.calendar_today,
                      isOverdue: reservation.isOverdue,
                    ),
                    if (isAdmin) ...[
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (reservation.status != 'borrowed' && 
                              reservation.status != 'returned')
                            TextButton.icon(
                              onPressed: () => onStatusChange(
                                reservation.id!,
                                'borrowed',
                              ),
                              icon: Icon(
                                Icons.check_circle_outline,
                                color: isDarkMode ? AppTheme.accentDark : AppTheme.primaryLight,
                              ),
                              label: const Text('Accept'),
                            ),
                          if (reservation.status == 'borrowed')
                            TextButton.icon(
                              onPressed: () => onStatusChange(
                                reservation.id!,
                                'returned',
                              ),
                              icon: Icon(
                                Icons.assignment_return_outlined,
                                color: isDarkMode ? AppTheme.accentDark : AppTheme.primaryLight,
                              ),
                              label: const Text('Return'),
                            ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: () => onDelete?.call(reservation.id!),
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            label: const Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    bool isOverdue = false,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isDarkMode ? AppTheme.accentDark : AppTheme.accentLight,
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: isSmallScreen ? 12 : 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: isSmallScreen ? 12 : 14,
                color: isOverdue ? Colors.red : null,
              ),
            ),
          ),
        ],
      ),
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
        horizontal: isSmallScreen ? 8 : 12,
        vertical: isSmallScreen ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: colors[reservation.status]?.withOpacity(0.8) ?? Colors.grey,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        reservation.status.toUpperCase(),
        style: TextStyle(
          color: Colors.white,
          fontSize: isSmallScreen ? 11 : 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
} 