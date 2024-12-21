import 'package:equatable/equatable.dart';
import '../models/borrowing_trend_point.dart';

abstract class DashboardState extends Equatable {}

class DashboardLoading extends DashboardState {
  @override
  List<Object?> get props => [];
}

class DashboardLoaded extends DashboardState {
  final int uniqueBooks;
  final int totalBooks;
  final int reservedBooks;
  final int borrowedBooks;
  final int overdueBooks;
  final List<BorrowingTrendPoint> borrowingTrends;

  DashboardLoaded({
    required this.uniqueBooks,
    required this.totalBooks,
    required this.reservedBooks,
    required this.borrowedBooks,
    required this.overdueBooks,
    required this.borrowingTrends,
  });

  @override
  List<Object?> get props => [
        uniqueBooks,
        totalBooks,
        reservedBooks,
        borrowedBooks,
        overdueBooks,
        borrowingTrends,
      ];
}

class DashboardError extends DashboardState {
  final String message;

  DashboardError(this.message);

  @override
  List<Object?> get props => [message];
} 