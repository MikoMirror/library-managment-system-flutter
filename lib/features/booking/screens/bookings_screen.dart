import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking.dart';
import '../../../core/services/database/firestore_service.dart';
import 'package:intl/intl.dart';

class BookingsScreen extends StatelessWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Bookings'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirestoreService().getAllBookings(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No bookings found'));
          }

          final bookings = snapshot.data!.docs
              .map((doc) => Booking.fromMap(doc.data() as Map<String, dynamic>, doc.id))
              .toList();

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Book Title')),
                DataColumn(label: Text('User')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Borrowed Date')),
                DataColumn(label: Text('Due Date')),
                DataColumn(label: Text('Actions')),
              ],
              rows: bookings.map((booking) {
                return DataRow(
                  cells: [
                    DataCell(
                      FutureBuilder<String>(
                        future: FirestoreService().getBookTitle(booking.bookId),
                        builder: (context, snapshot) {
                          return Text(snapshot.data ?? 'Loading...');
                        },
                      ),
                    ),
                    DataCell(
                      FutureBuilder<String>(
                        future: FirestoreService().getUserName(booking.userId),
                        builder: (context, snapshot) {
                          return Text(snapshot.data ?? 'Loading...');
                        },
                      ),
                    ),
                    DataCell(
                      Chip(
                        label: Text(booking.status),
                        backgroundColor: _getStatusColor(booking.status),
                      ),
                    ),
                    DataCell(Text(
                      DateFormat('yyyy-MM-dd').format(booking.borrowedDate.toDate()),
                    )),
                    DataCell(Text(
                      DateFormat('yyyy-MM-dd').format(booking.dueDate.toDate()),
                    )),
                    DataCell(Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (booking.status == 'pending')
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            onPressed: () => _approveBooking(context, booking.id!),
                            tooltip: 'Approve',
                          ),
                        if (booking.status == 'borrowed')
                          IconButton(
                            icon: const Icon(Icons.assignment_return, color: Colors.blue),
                            onPressed: () => _returnBook(context, booking.id!),
                            tooltip: 'Return',
                          ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteBooking(context, booking.id!),
                          tooltip: 'Delete',
                        ),
                      ],
                    )),
                  ],
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange.shade100;
      case 'borrowed':
        return Colors.blue.shade100;
      case 'returned':
        return Colors.green.shade100;
      case 'overdue':
        return Colors.red.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  Future<void> _approveBooking(BuildContext context, String bookingId) async {
    try {
      await FirestoreService().updateBookingStatus(bookingId, 'borrowed');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking approved')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _returnBook(BuildContext context, String bookingId) async {
    try {
      await FirestoreService().updateBookingStatus(bookingId, 'returned');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Book returned successfully')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _deleteBooking(BuildContext context, String bookingId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Booking'),
        content: const Text('Are you sure you want to delete this booking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await FirestoreService().deleteBooking(bookingId);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking deleted')),
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
} 