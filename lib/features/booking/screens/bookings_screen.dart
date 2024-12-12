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
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => BookingFilterCubit()),
        BlocProvider(
          create: (context) => BookingBloc(
            repository: BookingsRepository(firestore: FirebaseFirestore.instance),
          )..add(LoadBookings()),
        ),
      ],
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
              backgroundColor: Theme.of(context).colorScheme.surface,
              appBar: CustomAppBar(
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
    return BlocBuilder<BookingBloc, BookingState>(
      builder: (context, state) {
        if (state is BookingLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is BookingError) {
          return Center(child: Text('Error: ${state.message}'));
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
        return bookings.where((b) => b.status == 'borrowed').toList();
      case BookingFilter.returned:
        return bookings.where((b) => b.status == 'returned').toList();
      case BookingFilter.all:
      default:
        return bookings;
    }
  }
}
  