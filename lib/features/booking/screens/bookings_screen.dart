import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/booking_table.dart';
import '../widgets/booking_filter_section.dart';
import '../models/booking.dart';
import '../bloc/booking_bloc.dart';
import '../cubit/booking_filter_cubit.dart';
import '../../../core/services/database/firestore_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../auth/bloc/auth/auth_bloc.dart';
import '../../users/models/user_model.dart';
import '../repositories/bookings_repository.dart';

class BookingsScreen extends StatelessWidget {
  final FirestoreService firestoreService = FirestoreService();

  BookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => BookingFilterCubit()),
        BlocProvider(
          create: (context) => BookingBloc(
            repository: BookingsRepository(firestore: FirebaseFirestore.instance),
          )..add(LoadBookings()),
        ),
      ],
      child: Scaffold(
        backgroundColor: isDarkMode 
          ? AppTheme.backgroundDark 
          : AppTheme.backgroundLight,
        body: _BookingsScreenContent(firestoreService: firestoreService),
      ),
    );
  }
}

class _BookingsScreenContent extends StatelessWidget {
  final FirestoreService firestoreService;

  const _BookingsScreenContent({required this.firestoreService});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDarkMode ? AppTheme.primaryDark : AppTheme.primaryLight;
    final accentColor = isDarkMode ? AppTheme.accentDark : AppTheme.accentLight;
    
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthSuccess) {
          return Center(
            child: CircularProgressIndicator(
              color: accentColor,
            ),
          );
        }

        return StreamBuilder<DocumentSnapshot>(
          stream: firestoreService.getUserStream(authState.user.uid),
          builder: (context, userSnapshot) {
            if (!userSnapshot.hasData) {
              return Center(
                child: CircularProgressIndicator(
                  color: accentColor,
                ),
              );
            }

            final userData = userSnapshot.data!.data() as Map<String, dynamic>;
            final userModel = UserModel.fromMap(userData);
            final isAdmin = userModel.role == 'admin';

            return Column(
              children: [
                const BookingFilterSection(),
                Expanded(
                  child: _buildBookingsList(
                    context, 
                    isAdmin,
                    isDarkMode,
                    accentColor,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildBookingsList(
    BuildContext context, 
    bool isAdmin, 
    bool isDarkMode,
    Color accentColor,
  ) {
    return BlocBuilder<BookingBloc, BookingState>(
      builder: (context, state) {
        if (state is BookingLoading) {
          return Center(
            child: CircularProgressIndicator(
              color: accentColor,
            ),
          );
        }

        if (state is BookingError) {
          return Center(
            child: Text(
              'Error: ${state.message}',
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),
          );
        }

        if (state is BookingsLoaded) {
          return BlocBuilder<BookingFilterCubit, BookingFilter>(
            builder: (context, filter) {
              final filteredBookings = _filterBookings(state.bookings, filter);
              
              return BookingTable(
                bookings: filteredBookings,
                isAdmin: isAdmin,
                onStatusChange: (bookingId, newStatus) {
                  context.read<BookingBloc>().add(
                    UpdateBookingStatus(
                      bookingId: bookingId,
                      newStatus: newStatus,
                    ),
                  );
                },
                onDelete: (bookingId) {
                  context.read<BookingBloc>().add(
                    DeleteBooking(bookingId: bookingId),
                  );
                },
              );
            },
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  List<Booking> _filterBookings(List<Booking> bookings, BookingFilter filter) {
    switch (filter) {
      case BookingFilter.pending:
        return bookings.where((b) => b.status == 'pending').toList();
      case BookingFilter.borrowed:
        return bookings.where((b) => b.status == 'borrowed' && !b.isOverdue).toList();
      case BookingFilter.returned:
        return bookings.where((b) => b.status == 'returned').toList();
      case BookingFilter.overdue:
        return bookings.where((b) => b.currentStatus == 'overdue').toList();
      case BookingFilter.all:
      default:
        return bookings;
    }
  }
}
  