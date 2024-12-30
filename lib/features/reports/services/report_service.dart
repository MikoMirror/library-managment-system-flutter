import 'dart:io';
import '../models/report_data.dart';
import 'pdf_service.dart';
import '../../../core/services/database/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../features/reservation/models/reservation.dart';

class ReportService {
  final FirestoreService _firestoreService;
  final PdfService _pdfService;

  ReportService({
    FirestoreService? firestoreService,
    PdfService? pdfService,
  })  : _firestoreService = firestoreService ?? FirestoreService(),
        _pdfService = pdfService ?? PdfService();

  Future<File?> generateReport({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final reportData = await _gatherReportData(startDate, endDate);
    return await _pdfService.generateReport(reportData);
  }

  Future<ReportData> _gatherReportData(DateTime startDate, DateTime endDate) async {
    // Get trends data for totals
    final borrowedTrends = await _firestoreService.getBorrowingTrends(
      startDate: startDate,
      endDate: endDate,
      status: 'borrowed',
    );

    final returnedTrends = await _firestoreService.getBorrowingTrends(
      startDate: startDate,
      endDate: endDate,
      status: 'returned',
    );

    // Calculate totals from trends
    int totalBorrowed = borrowedTrends.fold(0, (sum, trend) => sum + trend.count);
    int totalReturned = returnedTrends.fold(0, (sum, trend) => sum + trend.count);

    // Get all reservations for the period
    final reservations = await _firestoreService.getReservations(
      startDate: startDate,
      endDate: endDate,
    );

    // Sort reservations by date, handling null values
    reservations.sort((a, b) {
      if (a?.borrowedDate == null || b?.borrowedDate == null) return 0;
      return b!.borrowedDate.compareTo(a!.borrowedDate);
    });

    // Filter out null values
    final validReservations = reservations.where((r) => r != null).toList();

    return ReportData(
      startDate: startDate,
      endDate: endDate,
      totalBorrowed: totalBorrowed,
      totalReturned: totalReturned,
      reservations: validReservations,
    );
  }
} 