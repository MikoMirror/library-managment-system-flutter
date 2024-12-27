import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/reservation_bloc.dart';
import '../models/reservation.dart';
import 'reservation_table.dart';
import 'reservation_filter_section.dart';


class ReservationListBase extends StatelessWidget {
  final String title;
  final bool isAdmin;
  final List<Reservation> Function(List<Reservation>) reservationsFilter;
  final Widget? trailing;

  const ReservationListBase({
    super.key,
    required this.title,
    required this.isAdmin,
    required this.reservationsFilter,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const ReservationFilterSection(),
        Expanded(
          child: BlocBuilder<ReservationBloc, ReservationState>(
            builder: (context, state) {
              if (state is ReservationLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is ReservationError) {
                return Center(child: Text(state.message));
              }

              if (state is ReservationsLoaded) {
                final filteredReservations = reservationsFilter(state.reservations);
                return ReservationTable(
                  reservations: filteredReservations,
                  isAdmin: isAdmin,
                  onStatusChange: (String reservationId, String newStatus) {
                    context.read<ReservationBloc>().add(
                          UpdateReservationStatus(
                            reservationId: reservationId,
                            newStatus: newStatus,
                          ),
                        );
                  },
                  onDelete: (String reservationId) {
                    context.read<ReservationBloc>().add(
                          DeleteReservation(reservationId: reservationId),
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