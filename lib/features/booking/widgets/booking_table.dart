import 'package:flutter/material.dart';
import '../models/booking.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/delete_booking_dialog.dart';

class BookingTable extends StatelessWidget {
  final List<Booking> bookings;
  final bool isAdmin;
  final Function(String, String) onStatusChange;
  final Function(String)? onDelete;

  const BookingTable({
    super.key,
    required this.bookings,
    required this.isAdmin,
    required this.onStatusChange,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 80),
              child: _buildMobileList(context),
            ),
          );
        } else {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 80),
              child: _buildWideTable(context, constraints.maxWidth),
            ),
          );
        }
      },
    );
  }

  Widget _buildWideTable(BuildContext context, double width) {
    final itemsPerRow = _calculateItemsPerRow(width);
    final rows = (bookings.length / itemsPerRow).ceil();

    return Column(
      children: List.generate(rows, (rowIndex) {
        final startIndex = rowIndex * itemsPerRow;
        final endIndex = (startIndex + itemsPerRow).clamp(0, bookings.length);
        final rowItems = bookings.sublist(startIndex, endIndex);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: rowItems.map((booking) {
            final statusColors = {
              'reserved': Colors.orange,
              'borrowed': Colors.blue,
              'returned': Colors.green,
              'overdue': Colors.red,
            };
            final statusColor = statusColors[booking.currentStatus.toLowerCase()] ?? Colors.grey;

            return Expanded(
              child: Card(
                margin: const EdgeInsets.all(8),
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: statusColor,
                        width: 16,
                      ),
                    ),
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      dividerColor: Colors.transparent,
                    ),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      childrenPadding: EdgeInsets.zero,
                      title: SizedBox(
                        height: 100,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  booking.bookTitle ?? 'Loading...',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    height: 1.3,
                                    fontSize: 18,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${booking.userName ?? 'Loading...'} (${booking.userLibraryNumber ?? 'N/A'})',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                booking.currentStatus.toUpperCase(),
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            border: Border(
                              top: BorderSide(
                                color: Theme.of(context).dividerColor,
                                width: 1,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Borrowed: ${booking.formattedBorrowedDate}',
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Due: ${booking.formattedDueDate}',
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: booking.isOverdue ? Colors.red : Colors.grey[600],
                                            fontWeight: booking.isOverdue ? FontWeight.bold : null,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (isAdmin) ...[
                                const SizedBox(height: 16),
                                const Divider(height: 1),
                                const SizedBox(height: 16),
                                _buildActionButtons(context, booking),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      }),
    );
  }

  int _calculateItemsPerRow(double width) {
    if (width < 600) return 1;
    if (width < 900) return 2;
    if (width < 1200) return 3;
    if (width < 1800) return 4;
    return 5;
  }

  Widget _buildMobileList(BuildContext context) {
    if (bookings.isEmpty) {
      return const Center(
        child: Text('No bookings available'),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        if (booking.id == null) return const SizedBox.shrink();

        final statusColors = {
          'reserved': Colors.orange,
          'borrowed': Colors.blue,
          'returned': Colors.green,
          'overdue': Colors.red,
        };
        final statusColor = statusColors[booking.currentStatus.toLowerCase()] ?? Colors.grey;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: statusColor,
                  width: 16,
                ),
              ),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(
                dividerColor: Colors.transparent, // Removes the default expansion tile divider
              ),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                childrenPadding: EdgeInsets.zero,
                title: SizedBox(
                  height: 100, // Fixed height for the title section
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.bookTitle ?? 'Loading...',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              height: 1.3,
                              fontSize: 18,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${booking.userName ?? 'Loading...'} (${booking.userLibraryNumber ?? 'N/A'})',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          booking.currentStatus.toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      border: Border(
                        top: BorderSide(
                          color: Theme.of(context).dividerColor,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Borrowed: ${booking.formattedBorrowedDate}',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Due: ${booking.formattedDueDate}',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: booking.isOverdue ? Colors.red : Colors.grey[600],
                                      fontWeight: booking.isOverdue ? FontWeight.bold : null,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (isAdmin) ...[
                          const SizedBox(height: 16),
                          const Divider(height: 1),
                          const SizedBox(height: 16),
                          _buildActionButtons(context, booking),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? textColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: textColor),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, Booking booking) {
    if (booking.id == null) return const SizedBox.shrink();
    
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    if (!isMobile) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isAdmin) ...[
            if (booking.status != 'borrowed' && booking.status != 'returned')
              IconButton(
                icon: const Icon(Icons.check_circle_outline),
                onPressed: () => onStatusChange(booking.id!, 'borrowed'),
                tooltip: 'Accept',
              ),
            if (booking.status == 'borrowed')
              IconButton(
                icon: const Icon(Icons.assignment_return_outlined),
                onPressed: () => onStatusChange(booking.id!, 'returned'),
                tooltip: 'Return',
              ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmDelete(context, booking),
              tooltip: 'Delete',
            ),
          ],
        ],
      );
    }

    // Mobile view buttons
    if (!isAdmin) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          if (booking.status != 'borrowed' && booking.status != 'returned')
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => onStatusChange(booking.id!, 'borrowed'),
                icon: const Icon(Icons.check_circle_outline, size: 20),
                label: const Text('Approve'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            )
          else if (booking.status == 'borrowed')
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => onStatusChange(booking.id!, 'returned'),
                icon: const Icon(Icons.assignment_return_outlined, size: 20),
                label: const Text('Return'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _confirmDelete(context, booking),
              icon: const Icon(Icons.delete_outline, size: 20),
              label: const Text('Remove'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, String status) {
    final statusColors = {
      'reserved': Colors.orange,
      'borrowed': Colors.blue,
      'returned': Colors.green,
      'overdue': Colors.red,
    };

    final color = statusColors[status.toLowerCase()] ?? Colors.grey;
    final displayStatus = status.toUpperCase();

    return Container(
      width: 120,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Text(
          displayStatus,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Booking booking) async {
    if (!context.mounted) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // Prevent closing by tapping outside
      builder: (BuildContext dialogContext) => DeleteBookingDialog(
        bookTitle: booking.bookTitle ?? 'Unknown Book',
      ),
    );

    if (!context.mounted) return;
    
    if (confirmed == true && onDelete != null) {
      onDelete!(booking.id!);
    }
  }
} 