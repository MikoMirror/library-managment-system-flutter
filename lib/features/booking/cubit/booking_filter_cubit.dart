import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models/search_filter.dart';

enum BookingFilter implements SearchFilter {
  all('All'),
  pending('Pending'),
  borrowed('Borrowed'),
  returned('Returned');

  @override
  final String label;
  const BookingFilter(this.label);
}

class BookingFilterCubit extends Cubit<BookingFilter> {
  BookingFilterCubit() : super(BookingFilter.all);

  void resetFilter() {
    emit(BookingFilter.all);
  }

  void searchBookings(String query) {
    // Keep current filter state while searching
    // You might want to combine this with other filter logic
    emit(state);
  }

  void updateFilter(BookingFilter filter) {
    emit(filter);
  }
} 