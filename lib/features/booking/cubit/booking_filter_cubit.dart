import 'package:flutter_bloc/flutter_bloc.dart';

enum BookingFilter { all, pending, borrowed, returned }

class BookingFilterCubit extends Cubit<BookingFilter> {
  BookingFilterCubit() : super(BookingFilter.all);

  void changeFilter(BookingFilter filter) {
    emit(filter);
  }
} 