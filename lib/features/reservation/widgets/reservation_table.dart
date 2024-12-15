import 'package:flutter/material.dart';
import '../models/reservation.dart';
import 'reservation_card.dart';

class ReservationTable extends StatelessWidget {
  final List<Reservation> reservations;
  final bool isAdmin;
  final Function(String, String) onStatusChange;
  final Function(String)? onDelete;

  const ReservationTable({
    super.key,
    required this.reservations,
    required this.isAdmin,
    required this.onStatusChange,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reservations.length,
      itemBuilder: (context, index) {
        final reservation = reservations[index];
        return ReservationCard(
          reservation: reservation,
          isAdmin: isAdmin,
          onStatusChange: onStatusChange,
          onDelete: onDelete,
        );
      },
    );
  }
} 