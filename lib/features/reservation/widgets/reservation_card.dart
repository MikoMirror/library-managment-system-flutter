import 'package:flutter/material.dart';
import '../models/reservation.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/delete_reservation_dialog.dart';
import '../bloc/reservation_card_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../cubit/reservation_selection_cubit.dart';

class ReservationCard extends StatelessWidget {
  final Reservation reservation;
  final bool isAdmin;
  final Function(String, String) onStatusChange;
  final Function(String)? onDelete;
  final bool isSelected;
  final VoidCallback? onLongPress;
  final VoidCallback? onTap;

  const ReservationCard({
    super.key,
    required this.reservation,
    required this.isAdmin,
    required this.onStatusChange,
    this.onDelete,
    this.isSelected = false,
    this.onLongPress,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReservationSelectionCubit, ReservationSelectionState>(
      builder: (context, selectionState) {
        return GestureDetector(
          onLongPress: onLongPress,
          onTap: () {
            if (selectionState.isSelectionMode) {
              // In selection mode, just toggle selection
              onTap?.call();
            } else {
              // Only show details when NOT in selection mode
              _showReservationDetails(context);
            }
          },
          child: Card(
            elevation: isSelected ? 4 : 1,
            color: isSelected 
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : null,
            child: BlocProvider(
              create: (context) => ReservationCardBloc(
                reservationId: reservation.id!,
                onStatusChange: onStatusChange,
                onDelete: onDelete,
              ),
              child: BlocBuilder<ReservationCardBloc, ReservationCardState>(
                builder: (context, state) {
                  if (state is ReservationCardLoading) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  
                  if (selectionState.isSelectionMode) {
                    // In selection mode, use ListTile with the same layout as ExpansionTile
                    return ListTile(
                      title: Row(
                        children: [
                          Icon(
                            Icons.book_outlined,
                            size: 20,
                            color: Theme.of(context).brightness == Brightness.dark 
                                ? AppTheme.dark.secondary 
                                : AppTheme.light.secondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        reservation.bookTitle ?? 'Loading...',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          fontSize: MediaQuery.of(context).size.width < 600 ? 14 : 16,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildQuantityBadge(context),
                                  ],
                                ),
                                if (reservation.isOverdue) ...[
                                  const SizedBox(height: 4),
                                  _buildOverdueBanner(context),
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
                            color: Theme.of(context).brightness == Brightness.dark 
                                ? AppTheme.dark.secondary 
                                : AppTheme.light.secondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${reservation.userName ?? 'Loading...'} (${reservation.userLibraryNumber ?? 'N/A'})',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontSize: MediaQuery.of(context).size.width < 600 ? 12 : 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  // Normal mode with ExpansionTile
                  return ExpansionTile(
                    title: Row(
                      children: [
                        Icon(
                          Icons.book_outlined,
                          size: 20,
                          color: Theme.of(context).brightness == Brightness.dark 
                              ? AppTheme.dark.secondary 
                              : AppTheme.light.secondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      reservation.bookTitle ?? 'Loading...',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: MediaQuery.of(context).size.width < 600 ? 14 : 16,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildQuantityBadge(context),
                                ],
                              ),
                              if (reservation.isOverdue) ...[
                                const SizedBox(height: 4),
                                _buildOverdueBanner(context),
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
                          color: Theme.of(context).brightness == Brightness.dark 
                              ? AppTheme.dark.secondary 
                              : AppTheme.light.secondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${reservation.userName ?? 'Loading...'} (${reservation.userLibraryNumber ?? 'N/A'})',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: MediaQuery.of(context).size.width < 600 ? 12 : 14,
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
                              DateFormat('dd/MM/yyyy').format(reservation.borrowedDate.toDate()),
                              Icons.calendar_today,
                            ),
                            _buildInfoRow(
                              context,
                              'Due',
                              DateFormat('dd/MM/yyyy').format(reservation.dueDate.toDate()),
                              Icons.event,
                              isOverdue: reservation.isOverdue,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (reservation.status == 'reserved') ...[
                                  TextButton.icon(
                                    onPressed: () {
                                      context.read<ReservationCardBloc>().add(
                                        UpdateCardStatus('borrowed'),
                                      );
                                    },
                                    icon: const Icon(Icons.check_circle_outline),
                                    label: const Text('Confirm'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton.icon(
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Delete Reservation'),
                                          content: const Text('Are you sure you want to delete this reservation?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                                context.read<ReservationCardBloc>().add(DeleteCard());
                                              },
                                              child: const Text('Delete'),
                                              style: TextButton.styleFrom(
                                                foregroundColor: Theme.of(context).colorScheme.error,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.delete_outline),
                                    label: const Text('Remove'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Theme.of(context).colorScheme.error,
                                    ),
                                  ),
                                ] else if (reservation.status == 'borrowed' || reservation.status == 'overdue') ...[
                                  TextButton.icon(
                                    onPressed: () {
                                      context.read<ReservationCardBloc>().add(
                                        UpdateCardStatus('returned'),
                                      );
                                    },
                                    icon: const Icon(Icons.assignment_return_outlined),
                                    label: const Text('Return Book'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton.icon(
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Delete Reservation'),
                                          content: const Text('Are you sure you want to delete this reservation?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                                context.read<ReservationCardBloc>().add(DeleteCard());
                                              },
                                              child: const Text('Delete'),
                                              style: TextButton.styleFrom(
                                                foregroundColor: Theme.of(context).colorScheme.error,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.delete_outline),
                                    label: const Text('Remove'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Theme.of(context).colorScheme.error,
                                    ),
                                  ),
                                ] else if (reservation.status == 'returned' || reservation.status == 'expired') ...[
                                  TextButton.icon(
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Delete Reservation'),
                                          content: const Text('Are you sure you want to delete this reservation?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                                context.read<ReservationCardBloc>().add(DeleteCard());
                                              },
                                              child: const Text('Delete'),
                                              style: TextButton.styleFrom(
                                                foregroundColor: Theme.of(context).colorScheme.error,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.delete_outline),
                                    label: const Text('Remove'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Theme.of(context).colorScheme.error,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void _showReservationDetails(BuildContext context) {
    // Your existing details dialog logic
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

    final displayValue = (label == 'Due' && reservation.status == 'returned')
        ? DateFormat('dd/MM/yyyy').format(DateTime.now())
        : value;

    final displayLabel = (label == 'Due' && reservation.status == 'returned') 
        ? 'Returned' 
        : label;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            (displayLabel == 'Returned') ? Icons.check_circle_outline : icon,
            size: 18,
            color: isDarkMode 
                ? AppTheme.dark.secondary 
                : AppTheme.light.secondary,
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(
              '$displayLabel:',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: isSmallScreen ? 12 : 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              displayValue,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: isSmallScreen ? 12 : 14,
                color: (isOverdue && reservation.status != 'returned') ? Colors.red : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityBadge(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 6 : 8,
        vertical: isSmallScreen ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: (isDarkMode ? AppTheme.dark.primary : AppTheme.light.primary).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isDarkMode ? AppTheme.dark.primary : AppTheme.light.primary).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        'Qty: ${reservation.quantity}',
        style: TextStyle(
          color: isDarkMode ? AppTheme.dark.primary : AppTheme.light.primary,
          fontSize: isSmallScreen ? 11 : 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    final coreColors = isDarkMode ? AppTheme.dark : AppTheme.light;
    
    final colors = {
      'pending': coreColors.warning,
      'borrowed': coreColors.success,
      'returned': coreColors.info,
      'rejected': coreColors.error,
      'overdue': coreColors.error,
      'expired': coreColors.expired,
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

  Widget _buildOverdueBanner(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 6 : 8,
        vertical: isSmallScreen ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: AppTheme.light.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: AppTheme.light.error.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.warning,
            size: isSmallScreen ? 12 : 14,
            color: AppTheme.light.error,
          ),
          const SizedBox(width: 4),
          Text(
            'Overdue',
            style: TextStyle(
              color: AppTheme.light.error,
              fontSize: isSmallScreen ? 11 : 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
} 