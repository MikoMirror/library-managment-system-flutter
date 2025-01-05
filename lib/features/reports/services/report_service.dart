import 'dart:io';
import '../models/report_data.dart';
import 'pdf_service.dart';
import '../../../core/services/firestore/books_firestore_service.dart';
import '../../../core/services/firestore/users_firestore_service.dart';
import 'package:logger/logger.dart';

class ReportService {
  final BooksFirestoreService _firestoreService;
  final PdfService _pdfService;
  final UsersFirestoreService _usersService;
  final BooksFirestoreService _booksService;
  final _logger = Logger();

  ReportService({
    BooksFirestoreService? firestoreService,
    PdfService? pdfService,
    UsersFirestoreService? usersService,
    BooksFirestoreService? booksService,
  })  : _firestoreService = firestoreService ?? BooksFirestoreService(),
        _pdfService = pdfService ?? PdfService(),
        _usersService = usersService ?? UsersFirestoreService(),
        _booksService = booksService ?? BooksFirestoreService();

  Future<File?> generateReport({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final reportData = await _gatherReportData(startDate, endDate);
    return await _pdfService.generateReport(reportData);
  }

  Future<ReportData> _gatherReportData(DateTime startDate, DateTime endDate) async {
    try {
      // Get reservations for the period
      final reservations = await _firestoreService.getReservationsForReport(
        startDate,
        endDate,
      );

      // Fetch book and user details for each reservation
      final enrichedReservations = await Future.wait(
        reservations.map((reservation) async {
          try {
            // Ensure we have valid IDs
            final userDoc = await _usersService.getUserById(reservation.userId);
            
            // Get book details
            final bookDoc = await _booksService.getDocument(
              BooksFirestoreService.collectionPath,
              reservation.bookId
            );
            final bookData = bookDoc.data() as Map<String, dynamic>?;

            // Update reservation with book and user details
            return reservation.copyWith(
              bookTitle: bookData?['title'] ?? 'Unknown',
              userName: userDoc?.name ?? 'Unknown',
              userLibraryNumber: userDoc?.libraryNumber ?? 'N/A',
            );
          } catch (e) {
            _logger.e('Error processing reservation ${reservation.id}: $e');
            return reservation;
          }
        }),
      );

      // Calculate totals with quantities
      int totalBorrowed = enrichedReservations
          .where((r) => r.status == 'borrowed')
          .length;
      
      int totalReturned = enrichedReservations
          .where((r) => r.status == 'returned')
          .length;

      // Calculate total books for each status
      int totalBorrowedBooks = enrichedReservations
          .where((r) => r.status == 'borrowed')
          .fold(0, (sum, r) => sum + r.quantity);
      
      int totalReturnedBooks = enrichedReservations
          .where((r) => r.status == 'returned')
          .fold(0, (sum, r) => sum + r.quantity);
      
      int totalOverdueBooks = enrichedReservations
          .where((r) => r.currentStatus == 'overdue')
          .fold(0, (sum, r) => sum + r.quantity);
      
      int totalExpiredBooks = enrichedReservations
          .where((r) => r.status == 'expired')
          .fold(0, (sum, r) => sum + r.quantity);

      // Sort reservations by date
      enrichedReservations.sort((a, b) => 
        b.borrowedDate.compareTo(a.borrowedDate)
      );

      return ReportData(
        startDate: startDate,
        endDate: endDate,
        totalBorrowed: totalBorrowed,
        totalReturned: totalReturned,
        totalBorrowedBooks: totalBorrowedBooks,
        totalReturnedBooks: totalReturnedBooks,
        totalOverdueBooks: totalOverdueBooks,
        totalExpiredBooks: totalExpiredBooks,
        reservations: enrichedReservations,
      );
    } catch (e) {
      _logger.e('Error gathering report data: $e');
      rethrow;
    }
  }
} 