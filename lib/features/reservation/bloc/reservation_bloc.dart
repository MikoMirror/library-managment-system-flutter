import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reservation.dart';
import '../repositories/reservation_repository.dart';

// Events
abstract class ReservationEvent {}

class LoadReservations extends ReservationEvent {
  final String? userId;

  LoadReservations({this.userId});
}

class CreateReservation extends ReservationEvent {
  final String userId;
  final String bookId;
  final int quantity;
  final String? selectedUserId;
  final Timestamp borrowedDate;
  final Timestamp dueDate;

  CreateReservation({
    required this.userId,
    required this.bookId,
    required this.quantity,
    this.selectedUserId,
    required this.borrowedDate,
    required this.dueDate,
  });
}

class UpdateReservationStatus extends ReservationEvent {
  final String reservationId;
  final String newStatus;

  UpdateReservationStatus({
    required this.reservationId,
    required this.newStatus,
  });
}

class DeleteReservation extends ReservationEvent {
  final String reservationId;

  DeleteReservation({required this.reservationId});
}

class RefreshReservations extends ReservationEvent {}

class CheckReservationStatuses extends ReservationEvent {}

class SearchReservations extends ReservationEvent {
  final String query;
  SearchReservations(this.query);
}

// States
abstract class ReservationState {}

class ReservationInitial extends ReservationState {}
class ReservationLoading extends ReservationState {}
class ReservationSuccess extends ReservationState {}
class ReservationError extends ReservationState {
  final String message;
  ReservationError(this.message);
}

class ReservationsLoaded extends ReservationState {
  final List<Reservation> reservations;
  ReservationsLoaded(this.reservations);
}

class ReservationBloc extends Bloc<ReservationEvent, ReservationState> {
  final ReservationsRepository repository;
  List<Reservation> _currentReservations = [];
  List<Reservation> _allReservations = [];

  ReservationBloc({required this.repository}) : super(ReservationInitial()) {
    on<LoadReservations>((event, emit) async {
      try {
        emit(ReservationLoading());
        _currentReservations = await repository.getReservations();
        _allReservations = _currentReservations;
        emit(ReservationsLoaded(_currentReservations));
      } catch (e) {
        emit(ReservationError(e.toString()));
      }
    });
    on<CreateReservation>(_onCreateReservation);
    on<UpdateReservationStatus>(_onUpdateReservationStatus);
    on<DeleteReservation>(_onDeleteReservation);
    on<RefreshReservations>((event, emit) async {
      try {
        _currentReservations = await repository.getReservations();
        emit(ReservationsLoaded(_currentReservations));
      } catch (e) {
        emit(ReservationError(e.toString()));
      }
    });
    on<CheckReservationStatuses>((event, emit) async {
      try {
        await repository.checkAndUpdateOverdueReservations();
        add(RefreshReservations());
      } catch (e) {
        emit(ReservationError(e.toString()));
      }
    });
    on<SearchReservations>((event, emit) {
      if (_allReservations.isEmpty) {
        _allReservations = _currentReservations;
      }

      if (event.query.isEmpty) {
        emit(ReservationsLoaded(_allReservations));
        return;
      }

      final searchQuery = event.query.toLowerCase();
      final filteredReservations = _allReservations.where((reservation) {
        final bookTitle = reservation.bookTitle?.toLowerCase() ?? '';
        final userName = reservation.userName?.toLowerCase() ?? '';
        final userLibraryNumber = reservation.userLibraryNumber?.toLowerCase() ?? '';
        
        return bookTitle.contains(searchQuery) ||
               userName.contains(searchQuery) ||
               userLibraryNumber.contains(searchQuery);
      }).toList();

      emit(ReservationsLoaded(filteredReservations));
    });
  }

  Future<void> _onCreateReservation(CreateReservation event, Emitter<ReservationState> emit) async {
    emit(ReservationLoading());
    try {
      // Validate the reservation date
      final isValidDate = await repository.validateReservationDate(
        event.borrowedDate.toDate(),
      );

      if (!isValidDate) {
        emit(ReservationError('Cannot reserve more than the allowed days in advance'));
        return;
      }

      await repository.createReservation(
        userId: event.selectedUserId ?? event.userId,
        bookId: event.bookId,
        status: 'reserved',
        borrowedDate: event.borrowedDate,
        dueDate: event.dueDate,
        quantity: event.quantity,
      );
      emit(ReservationSuccess());
      add(LoadReservations());
    } catch (e) {
      emit(ReservationError(e.toString()));
    }
  }

  Future<void> _onUpdateReservationStatus(
    UpdateReservationStatus event, 
    Emitter<ReservationState> emit
  ) async {
    emit(ReservationLoading());
    try {
      await repository.updateReservationStatus(
        reservationId: event.reservationId,
        newStatus: event.newStatus,
      );
      
      _currentReservations = _currentReservations.map((reservation) {
        if (reservation.id == event.reservationId) {
          return reservation.copyWith(status: event.newStatus);
        }
        return reservation;
      }).toList();
      
      emit(ReservationsLoaded(_currentReservations));
      add(RefreshReservations());
    } catch (e) {
      emit(ReservationError(e.toString()));
    }
  }

  Future<void> _onDeleteReservation(DeleteReservation event, Emitter<ReservationState> emit) async {
    try {
      await repository.deleteReservation(event.reservationId);
      
      _currentReservations = _currentReservations
          .where((reservation) => reservation.id != event.reservationId)
          .toList();
          
      emit(ReservationsLoaded(_currentReservations));
    } catch (e) {
      emit(ReservationError(e.toString()));
    }
  }
} 