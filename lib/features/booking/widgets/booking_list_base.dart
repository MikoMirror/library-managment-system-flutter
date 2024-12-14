import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/booking_bloc.dart';
import '../cubit/booking_filter_cubit.dart';
import '../models/booking.dart';
import '../widgets/booking_table.dart';
import '../widgets/booking_filter_section.dart';
import '../../../core/theme/app_theme.dart';

class BookingListBase extends StatelessWidget {
  final String title;
  final bool isAdmin;
  final List<Booking> Function(List<Booking>) bookingsFilter;
  final Widget? trailing;

  const BookingListBase({
    super.key,
    required this.title,
    required this.isAdmin,
    required this.bookingsFilter,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BookingFilterSection(),
        Expanded(
          child: BlocBuilder<BookingBloc, BookingState>(
            builder: (context, state) {
              if (state is BookingLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is BookingError) {
                return Center(child: Text(state.message));
              }

              if (state is BookingsLoaded) {
                final filteredBookings = bookingsFilter(state.bookings);
                return BookingTable(
                  bookings: filteredBookings,
                  isAdmin: isAdmin,
                  onStatusChange: (String bookingId, String newStatus) {
                    context.read<BookingBloc>().add(
                          UpdateBookingStatus(
                            bookingId: bookingId,
                            newStatus: newStatus,
                          ),
                        );
                  },
                  onDelete: (String bookingId) {
                    context.read<BookingBloc>().add(
                          DeleteBooking(bookingId: bookingId),
                        );
                  },
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }
} 