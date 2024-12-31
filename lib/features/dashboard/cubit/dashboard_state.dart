import '../models/borrowing_trend_point.dart';

abstract class DashboardState {
  final DateTime selectedStartDate;
  final DateTime selectedEndDate;

  const DashboardState({
    required this.selectedStartDate,
    required this.selectedEndDate,
  });
}

class DashboardInitial extends DashboardState {
  DashboardInitial({
    required super.selectedStartDate,
    required super.selectedEndDate,
  });
}

class DashboardLoading extends DashboardState {
  DashboardLoading({
    required DateTime startDate,
    required DateTime endDate,
  }) : super(
    selectedStartDate: startDate,
    selectedEndDate: endDate,
  );
}

class DashboardLoaded extends DashboardState {
  final List<BorrowingTrendPoint> borrowedTrends;
  final List<BorrowingTrendPoint> returnedTrends;
  final int uniqueBooks;
  final int totalBooks;
  final int reservedBooks;
  final int borrowedBooks;
  final int overdueBooks;

  const DashboardLoaded({
    required this.borrowedTrends,
    required this.returnedTrends,
    required this.uniqueBooks,
    required this.totalBooks,
    required this.reservedBooks,
    required this.borrowedBooks,
    required this.overdueBooks,
    required super.selectedStartDate,
    required super.selectedEndDate,
  });
}

class DashboardError extends DashboardState {
  final String message;

  DashboardError(
    this.message, {
    required DateTime startDate,
    required DateTime endDate,
  }) : super(
    selectedStartDate: startDate,
    selectedEndDate: endDate,
  );
} 