import 'package:flutter_bloc/flutter_bloc.dart';
import 'dashboard_state.dart';
import '../../../core/services/firestore/books_firestore_service.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final BooksFirestoreService _firestoreService;

  DashboardCubit(this._firestoreService) : super(DashboardInitial(
    selectedStartDate: DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day - 13,
      0, 0, 0,
    ),
    selectedEndDate: DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
      23, 59, 59,
    ),
  ));

  Future<void> loadDashboard({DateTime? startDate, DateTime? endDate}) async {
    try {
      final effectiveStartDate = startDate ?? state.selectedStartDate;
      final effectiveEndDate = endDate ?? state.selectedEndDate;

      emit(DashboardLoading(
        startDate: effectiveStartDate,
        endDate: effectiveEndDate,
      ));

      final stats = await _firestoreService.getBookStats();
      final borrowedTrends = await _firestoreService.getBorrowingTrends(
        startDate: effectiveStartDate,
        endDate: effectiveEndDate,
        status: 'borrowed',
      );
      final returnedTrends = await _firestoreService.getBorrowingTrends(
        startDate: effectiveStartDate,
        endDate: effectiveEndDate,
        status: 'returned',
      );

      emit(DashboardLoaded(
        uniqueBooks: stats['uniqueBooks'] ?? 0,
        totalBooks: stats['totalBooks'] ?? 0,
        reservedBooks: stats['reservedBooks'] ?? 0,
        borrowedBooks: stats['borrowedBooks'] ?? 0,
        overdueBooks: stats['overdueBooks'] ?? 0,
        borrowedTrends: borrowedTrends,
        returnedTrends: returnedTrends,
        selectedStartDate: effectiveStartDate,
        selectedEndDate: effectiveEndDate,
      ));
    } catch (e) {
      emit(DashboardError(
        'Failed to load dashboard data',
        startDate: state.selectedStartDate,
        endDate: state.selectedEndDate,
      ));
    }
  }
} 