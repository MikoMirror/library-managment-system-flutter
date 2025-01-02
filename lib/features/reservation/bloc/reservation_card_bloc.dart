// lib/features/reservation/bloc/reservation_card_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';

// Events
abstract class ReservationCardEvent {}

class UpdateCardStatus extends ReservationCardEvent {
  final String newStatus;
  UpdateCardStatus(this.newStatus);
}

class DeleteCard extends ReservationCardEvent {}

// States
abstract class ReservationCardState {}

class ReservationCardInitial extends ReservationCardState {}
class ReservationCardLoading extends ReservationCardState {}
class ReservationCardSuccess extends ReservationCardState {}
class ReservationCardError extends ReservationCardState {
  final String message;
  ReservationCardError(this.message);
}
class ReservationCardStatusUpdated extends ReservationCardState {
  final String newStatus;
  ReservationCardStatusUpdated(this.newStatus);
}
class ReservationCardDeleted extends ReservationCardState {}

class ReservationCardBloc extends Bloc<ReservationCardEvent, ReservationCardState> {
  final String reservationId;
  final Function(String, String) onStatusChange;
  final Function(String)? onDelete;

  ReservationCardBloc({
    required this.reservationId,
    required this.onStatusChange,
    this.onDelete,
  }) : super(ReservationCardInitial()) {
    on<UpdateCardStatus>((event, emit) async {
      emit(ReservationCardLoading());
      try {
        if (!_isValidStatusTransition(event.newStatus)) {
          throw Exception('Invalid status transition');
        }

        await onStatusChange(reservationId, event.newStatus);
        emit(ReservationCardStatusUpdated(event.newStatus));
      } catch (e) {
        emit(ReservationCardError(e.toString()));
      }
    });

    on<DeleteCard>((event, emit) async {
      emit(ReservationCardLoading());
      try {
        if (onDelete == null) {
          throw Exception('Delete operation not supported');
        }
        await onDelete!(reservationId);
        emit(ReservationCardDeleted());
      } catch (e) {
        emit(ReservationCardError(e.toString()));
      }
    });
  }

  bool _isValidStatusTransition(String newStatus) {
    return ['reserved', 'borrowed', 'returned', 'expired', 'overdue', 'canceled']
        .contains(newStatus);
  }
}