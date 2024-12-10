import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../repositories/bookings_repository.dart';

// Events
abstract class BookingEvent {}

class CreateBooking extends BookingEvent {
  final String userId;
  final String bookId;
  final int quantity;
  final String? selectedUserId; // For admin use

  CreateBooking({
    required this.userId,
    required this.bookId,
    required this.quantity,
    this.selectedUserId,
  });
}

class UpdateBookingStatus extends BookingEvent {
  final String bookingId;
  final String newStatus;

  UpdateBookingStatus({
    required this.bookingId,
    required this.newStatus,
  });
}

// States
abstract class BookingState {}

class BookingInitial extends BookingState {}
class BookingLoading extends BookingState {}
class BookingSuccess extends BookingState {}
class BookingError extends BookingState {
  final String message;
  BookingError(this.message);
}

class BookingBloc extends Bloc<BookingEvent, BookingState> {
  final BookingsRepository _repository;

  BookingBloc({required BookingsRepository repository})
      : _repository = repository,
        super(BookingInitial()) {
    on<CreateBooking>(_onCreateBooking);
    on<UpdateBookingStatus>(_onUpdateBookingStatus);
  }

  Future<void> _onCreateBooking(CreateBooking event, Emitter<BookingState> emit) async {
    emit(BookingLoading());
    try {
      await _repository.createBooking(
        userId: event.selectedUserId ?? event.userId,
        bookId: event.bookId,
        status: 'pending',
        borrowedDate: Timestamp.now(),
        dueDate: Timestamp.fromDate(DateTime.now().add(const Duration(days: 14))),
        quantity: event.quantity,
      );
      emit(BookingSuccess());
    } catch (e) {
      emit(BookingError(e.toString()));
    }
  }

  Future<void> _onUpdateBookingStatus(
    UpdateBookingStatus event, 
    Emitter<BookingState> emit
  ) async {
    emit(BookingLoading());
    try {
      await _repository.updateBookingStatus(
        bookingId: event.bookingId,
        status: event.newStatus,
      );
      emit(BookingSuccess());
    } catch (e) {
      emit(BookingError(e.toString()));
    }
  }
} 