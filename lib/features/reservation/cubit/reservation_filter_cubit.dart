import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models/search_filter.dart';

enum ReservationFilter implements SearchFilter {
  all('All'),
  reserved('Reserved'),
  borrowed('Borrowed'),
  overdue('Overdue'),
  returned('Returned'),
  expired('Expired');

  final String displayName;
  const ReservationFilter(this.displayName);

  @override
  String getDisplayName() => displayName;

  @override
  String get label => displayName;
}

class ReservationFilterCubit extends Cubit<ReservationFilter> {
  ReservationFilterCubit() : super(ReservationFilter.all);

  void updateFilter(ReservationFilter filter) {
    emit(filter);
  }
} 