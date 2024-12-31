import 'package:library_management_system/features/reservation/models/reservation.dart';

class ReportData {
  final DateTime startDate;
  final DateTime endDate;
  final int totalBorrowed;
  final int totalReturned;
  final int totalBorrowedBooks;
  final int totalReturnedBooks;
  final int totalOverdueBooks;
  final int totalExpiredBooks;
  final List<Reservation> reservations;

  ReportData({
    required this.startDate,
    required this.endDate,
    required this.totalBorrowed,
    required this.totalReturned,
    required this.totalBorrowedBooks,
    required this.totalReturnedBooks,
    required this.totalOverdueBooks,
    required this.totalExpiredBooks,
    required this.reservations,
  });
} 