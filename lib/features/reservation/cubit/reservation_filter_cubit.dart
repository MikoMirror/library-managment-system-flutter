import 'package:flutter_bloc/flutter_bloc.dart';

enum ReservationFilter {
  all,
  reserved,
  borrowed,
  returned,
  overdue,
  expired,
  canceled;

  String get displayName {
    switch (this) {
      case ReservationFilter.all:
        return 'All';
      case ReservationFilter.reserved:
        return 'Reserved';
      case ReservationFilter.borrowed:
        return 'Borrowed';
      case ReservationFilter.returned:
        return 'Returned';
      case ReservationFilter.overdue:
        return 'Overdue';
      case ReservationFilter.expired:
        return 'Expired';
      case ReservationFilter.canceled:
        return 'Canceled';
    }
  }
}

class ReservationFilterCubit extends Cubit<ReservationFilter> {
  ReservationFilterCubit() : super(ReservationFilter.all);

  void updateFilter(ReservationFilter filter) {
    emit(filter);
  }
} 