import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/booking_table.dart';
import '../widgets/booking_filter_section.dart';
import '../models/booking.dart';
import '../bloc/booking_bloc.dart';
import '../../../core/services/database/firestore_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/bloc/auth/auth_bloc.dart';
import '../../users/models/user_model.dart';
import '../cubit/booking_filter_cubit.dart';

class BookingsScreen extends StatelessWidget {
  final FirestoreService firestoreService = FirestoreService();

  BookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => BookingFilterCubit(),
      child: _BookingsScreenContent(firestoreService: firestoreService),
    );
  }
}

class _BookingsScreenContent extends StatelessWidget {
  final FirestoreService firestoreService;

  const _BookingsScreenContent({required this.firestoreService});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthSuccess) {
          return Center(
            child: CircularProgressIndicator(
              color: isDarkMode ? AppTheme.accentDark : AppTheme.primaryLight,
            ),
          );
        }

        return StreamBuilder<DocumentSnapshot>(
          stream: firestoreService.getUserStream(authState.user.uid),
          builder: (context, userSnapshot) {
            if (!userSnapshot.hasData) {
              return Center(
                child: CircularProgressIndicator(
                  color: isDarkMode ? AppTheme.accentDark : AppTheme.primaryLight,
                ),
              );
            }

            final userData = userSnapshot.data!.data() as Map<String, dynamic>;
            final userModel = UserModel.fromMap(userData);
            final isAdmin = userModel.role == 'admin';

            return Scaffold(
              backgroundColor: Theme.of(context).colorScheme.background,
              appBar: AppBar(
                elevation: 0,
                backgroundColor: Colors.transparent,
                title: Text(
                  'Bookings Management',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                      Icons.refresh,
                      color: isDarkMode ? AppTheme.accentDark : AppTheme.accentLight,
                    ),
                    tooltip: 'Refresh bookings',
                    onPressed: () {
                      // Trigger a refresh if needed
                    },
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              body: Column(
                children: [
                  const BookingFilterSection(),
                  Expanded(
                    child: _buildBookingsList(context, isAdmin),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBookingsList(BuildContext context, bool isAdmin) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<QuerySnapshot>(
      stream: firestoreService.getAllBookings(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              color: isDarkMode ? AppTheme.accentDark : AppTheme.primaryLight,
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'No bookings found',
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.black54,
                fontSize: 16,
              ),
            ),
          );
        }

        final bookings = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return Booking.fromMap(data, doc.id);
        }).toList();

        return BlocBuilder<BookingFilterCubit, BookingFilter>(
          builder: (context, filter) {
            final filteredBookings = _filterBookings(bookings, filter);

            return FutureBuilder<List<Booking>>(
              future: Future.wait(
                filteredBookings.map((booking) => _fetchBookingDetails(booking)),
              ),
              builder: (context, bookingsSnapshot) {
                if (!bookingsSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final updatedBookings = bookingsSnapshot.data!;

                return BookingTable(
                  bookings: updatedBookings,
                  isAdmin: isAdmin,
                  onStatusChange: (bookingId, newStatus) {
                    context.read<BookingBloc>().add(
                      UpdateBookingStatus(
                        bookingId: bookingId,
                        newStatus: newStatus,
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  List<Booking> _filterBookings(List<Booking> bookings, BookingFilter filter) {
    switch (filter) {
      case BookingFilter.pending:
        return bookings.where((b) => b.status == 'pending').toList();
      case BookingFilter.borrowed:
        return bookings.where((b) => b.status == 'borrowed').toList();
      case BookingFilter.returned:
        return bookings.where((b) => b.status == 'returned').toList();
      case BookingFilter.all:
      default:
        return bookings;
    }
  }

  Future<Booking> _fetchBookingDetails(Booking booking) async {
    if (booking.bookTitle == null || booking.userName == null) {
      final futures = await Future.wait([
        FirebaseFirestore.instance
            .collection('books')
            .doc(booking.bookId)
            .get(),
        FirebaseFirestore.instance
            .collection('users')
            .doc(booking.userId)
            .get(),
      ]);

      final bookDoc = futures[0];
      final userDoc = futures[1];

      return booking.copyWith(
        bookTitle: bookDoc.exists ? (bookDoc.data()?['title'] as String?) : 'Unknown Book',
        userName: userDoc.exists ? (userDoc.data()?['name'] as String?) : 'Unknown User',
      );
    }
    return booking;
  }
}
  