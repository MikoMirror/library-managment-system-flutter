import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking.dart';
import '../repositories/bookings_repository.dart';

// Events
abstract class BookingEvent {}

class LoadBookings extends BookingEvent {
  final String? userId;

  LoadBookings({this.userId});
}

class CreateBooking extends BookingEvent {
  final String userId;
  final String bookId;
  final int quantity;
  final String? selectedUserId;
  final Timestamp borrowedDate;
  final Timestamp dueDate;

  CreateBooking({
    required this.userId,
    required this.bookId,
    required this.quantity,
    this.selectedUserId,
    required this.borrowedDate,
    required this.dueDate,
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

class DeleteBooking extends BookingEvent {
  final String bookingId;

  DeleteBooking({required this.bookingId});
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

class BookingsLoaded extends BookingState {
  final List<Booking> bookings;
  BookingsLoaded(this.bookings);
}

class BookingBloc extends Bloc<BookingEvent, BookingState> {
  final BookingsRepository repository;

  BookingBloc({required this.repository}) : super(BookingInitial()) {
    on<LoadBookings>((event, emit) async {
      try {
        emit(BookingLoading());
        final bookings = await repository.getBookings();
        emit(BookingsLoaded(bookings));
      } catch (e) {
        emit(BookingError(e.toString()));
      }
    });
    on<CreateBooking>(_onCreateBooking);
    on<UpdateBookingStatus>(_onUpdateBookingStatus);
    on<DeleteBooking>(_onDeleteBooking);
  }

  Future<void> _onCreateBooking(CreateBooking event, Emitter<BookingState> emit) async {
    emit(BookingLoading());
    try {
      await repository.createBooking(
        userId: event.selectedUserId ?? event.userId,
        bookId: event.bookId,
        status: 'reserved',
        borrowedDate: event.borrowedDate,
        dueDate: event.dueDate,
        quantity: event.quantity,
      );
      emit(BookingSuccess());
      add(LoadBookings());
    } catch (e) {
      emit(BookingError(e.toString()));
    }
  }

  Future<void> _onUpdateBookingStatus(UpdateBookingStatus event, Emitter<BookingState> emit) async {
    emit(BookingLoading());
    try {
      await repository.updateBookingStatus(
        bookingId: event.bookingId,
        newStatus: event.newStatus,
      );
      emit(BookingSuccess());
      add(LoadBookings());
    } catch (e) {
      emit(BookingError(e.toString()));
    }
  }

  Future<void> _onDeleteBooking(DeleteBooking event, Emitter<BookingState> emit) async {
    emit(BookingLoading());
    try {
      await repository.deleteBooking(event.bookingId);
      emit(BookingSuccess());
      add(LoadBookings());
    } catch (e) {
      emit(BookingError(e.toString()));
    }
  }
} 