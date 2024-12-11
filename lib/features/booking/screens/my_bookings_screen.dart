import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/booking_bloc.dart';
import '../models/booking.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/bloc/auth/auth_bloc.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  @override
  void initState() {
    super.initState();
    // Load bookings when screen initializes
    context.read<BookingBloc>().add(LoadBookings());
  }

  void _showCancelConfirmationDialog(BuildContext context, String bookingId, String bookTitle) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancel Booking'),
          content: Text('Are you sure you want to cancel your booking for "$bookTitle"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () {
                context.read<BookingBloc>().add(DeleteBooking(bookingId: bookingId));
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Yes, Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthSuccess) {
          return const Center(child: CircularProgressIndicator());
        }

        return Scaffold(
          appBar: CustomAppBar(
            title: const Text('My Bookings'),
          ),
          body: BlocBuilder<BookingBloc, BookingState>(
            builder: (context, state) {
              if (state is BookingLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is BookingError) {
                return Center(child: Text('Error: ${state.message}'));
              }

              if (state is BookingsLoaded) {
                final userBookings = state.bookings
                    .where((booking) => booking.userId == authState.user.uid)
                    .toList();

                if (userBookings.isEmpty) {
                  return const Center(
                    child: Text(
                      'You have no bookings yet',
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        elevation: 2,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowColor: MaterialStateProperty.all(
                              Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
                            ),
                            columns: const [
                              DataColumn(label: Text('Book Title')),
                              DataColumn(label: Text('Borrow Date')),
                              DataColumn(label: Text('Due Date')),
                              DataColumn(label: Text('Status')),
                              DataColumn(label: Text('Actions')),
                            ],
                            rows: userBookings.map((booking) {
                              final isOverdue = booking.isOverdue;
                              
                              return DataRow(
                                cells: [
                                  DataCell(Text(booking.bookTitle ?? 'Unknown Book')),
                                  DataCell(Text(booking.formattedBorrowedDate)),
                                  DataCell(Text(
                                    booking.formattedDueDate,
                                    style: TextStyle(
                                      color: isOverdue ? Colors.red : null,
                                      fontWeight: isOverdue ? FontWeight.bold : null,
                                    ),
                                  )),
                                  DataCell(_buildStatusChip(booking.status)),
                                  DataCell(_buildActionButton(
                                    context,
                                    booking,
                                  )),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return const Center(child: Text('No bookings found'));
            },
          ),
        );
      },
    );
  }

  Widget _buildActionButton(BuildContext context, Booking booking) {
    if (booking.status.toLowerCase() == 'returned') {
      return const SizedBox.shrink();
    }

    return TextButton.icon(
      onPressed: () => _showCancelConfirmationDialog(
        context,
        booking.id!,
        booking.bookTitle ?? 'Unknown Book',
      ),
      icon: const Icon(Icons.cancel_outlined, color: Colors.red, size: 20),
      label: const Text(
        'Cancel',
        style: TextStyle(color: Colors.red),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: Size.zero,
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color chipColor;
    IconData? icon;
    String displayStatus = status.toUpperCase();
    
    switch (status.toLowerCase()) {
      case 'borrowed':
        chipColor = Colors.blue;
        icon = Icons.book;
        break;
      case 'returned':
        chipColor = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'overdue':
        chipColor = Colors.red;
        icon = Icons.warning;
        break;
      default:
        chipColor = Colors.grey;
        icon = Icons.help;
    }

    return Chip(
      label: Text(
        displayStatus,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
        ),
      ),
      backgroundColor: chipColor,
      avatar: Icon(
        icon,
        color: Colors.white,
        size: 16,
      ),
    );
  }
} 