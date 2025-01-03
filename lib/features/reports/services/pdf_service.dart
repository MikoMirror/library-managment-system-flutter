import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/report_data.dart';
import '../../../features/reservation/models/reservation.dart';
import 'dart:math' show max;

// Conditional import for web
import 'pdf_web.dart' if (dart.library.io) 'pdf_mobile.dart';

class PdfService {
  final PdfPlatformHelper _platformHelper = PdfPlatformHelper();

  Future<File?> generateReport(ReportData data) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageTheme: _buildPageTheme(),
        build: (context) {
          return [
            _buildHeader(data),
            pw.SizedBox(height: 20),
            _buildSummarySection(data),
            pw.SizedBox(height: 30),
            _buildReservationsSection(data.reservations),
          ];
        },
      ),
    );

    final bytes = await pdf.save();
    return _platformHelper.handlePdfBytes(bytes);
  }

  pw.Widget _buildHeader(ReportData data) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    return pw.Header(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Library Activity Report',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.Text(
              'Period: ${dateFormat.format(data.startDate)} - ${dateFormat.format(data.endDate)}'),
          pw.Text('Generated on: ${dateFormat.format(DateTime.now())}'),
          pw.Divider(),
        ],
      ),
    );
  }

  pw.Widget _buildSummarySection(ReportData data) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Summary',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        _buildSummaryGrid(data),
        pw.SizedBox(height: 20),
        _buildSummaryChart(data),
      ],
    );
  }

  pw.Widget _buildSummaryGrid(ReportData data) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
      ),
      child: pw.Column(
        children: [
          _buildSummaryRow('Total Reservations', '${data.reservations.length}'),
          _buildSummaryRow('Borrowed Reservations', '${data.totalBorrowed}'),
          _buildSummaryRow('Returned Reservations', '${data.totalReturned}'),
          pw.SizedBox(height: 10),
          pw.Divider(),
          pw.SizedBox(height: 10),
          _buildSummaryRow('Total Books Borrowed', '${data.totalBorrowedBooks}'),
          _buildSummaryRow('Total Books Returned', '${data.totalReturnedBooks}'),
          _buildSummaryRow('Total Books Overdue', '${data.totalOverdueBooks}'),
          _buildSummaryRow('Total Books Expired', '${data.totalExpiredBooks}'),
        ],
      ),
    );
  }

  pw.Widget _buildSummaryChart(ReportData data) {
    final borrowed = data.reservations.where((r) => r.status == 'borrowed').length.toDouble();
    final returned = data.reservations.where((r) => r.status == 'returned').length.toDouble();
    final overdue = data.reservations.where((r) => r.currentStatus == 'overdue').length.toDouble();
    final expired = data.reservations.where((r) => r.status == 'expired').length.toDouble();

    final maxValue = [borrowed, returned, overdue, expired].reduce(max);
    final chartMaxValue = maxValue + (maxValue * 0.2);

    final gridLines = List<double>.generate(8, (i) => chartMaxValue * i / 7);

    return pw.Container(
      height: 250,
      padding: const pw.EdgeInsets.fromLTRB(15, 15, 15, 25),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Container(
            width: 25,
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: gridLines.reversed.map((value) => pw.Padding(
                padding: const pw.EdgeInsets.only(right: 5),
                child: pw.Text(
                  value.toStringAsFixed(0),
                  style: const pw.TextStyle(fontSize: 8),
                ),
              )).toList(),
            ),
          ),
          pw.Expanded(
            child: pw.Stack(
              children: [
                pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: gridLines.map((value) => pw.Container(
                    height: 1,
                    color: PdfColors.grey300,
                  )).toList(),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 20),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      _buildChartBar('Borrowed', borrowed, chartMaxValue, PdfColors.blue700),
                      _buildChartBar('Returned', returned, chartMaxValue, PdfColors.green700),
                      _buildChartBar('Overdue', overdue, chartMaxValue, PdfColors.red700),
                      _buildChartBar('Expired', expired, chartMaxValue, PdfColors.grey700),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildChartBar(String label, double value, double maxValue, PdfColor color) {
    final height = value / maxValue;
    
    return pw.Container(
      width: 50,
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            value.toStringAsFixed(0),
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Container(
            width: 35,
            height: 180 * height,
            decoration: pw.BoxDecoration(
              color: color,
              borderRadius: const pw.BorderRadius.vertical(top: pw.Radius.circular(3)),
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            label,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
              fontSize: 8,
              color: PdfColors.grey800,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSummaryRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label),
          pw.Text(
            value,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildReservationsSection(List<Reservation> reservations) {
    final borrowed = reservations.where((r) => r.status == 'borrowed').toList();
    final returned = reservations.where((r) => r.status == 'returned').toList();
    final overdue = reservations.where((r) => r.currentStatus == 'overdue').toList();
    final expired = reservations.where((r) => r.status == 'expired').toList();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (borrowed.isNotEmpty)
          pw.Table(
            children: [
              pw.TableRow(
                children: [
                  _buildTableWithHeader('Currently Borrowed Books', borrowed),
                ],
              ),
            ],
          ),
        if (overdue.isNotEmpty)
          pw.Table(
            children: [
              pw.TableRow(
                children: [
                  _buildTableWithHeader('Overdue Books', overdue),
                ],
              ),
            ],
          ),
        if (returned.isNotEmpty)
          pw.Table(
            children: [
              pw.TableRow(
                children: [
                  _buildTableWithHeader('Returned Books', returned),
                ],
              ),
            ],
          ),
        if (expired.isNotEmpty)
          pw.Table(
            children: [
              pw.TableRow(
                children: [
                  _buildTableWithHeader('Expired Reservations', expired),
                ],
              ),
            ],
          ),
      ],
    );
  }

  pw.Widget _buildTableWithHeader(String title, List<Reservation> reservations) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Header(
          level: 1,
          child: _buildSectionHeader(title),
        ),
        _buildPaginatedTable(reservations),
        pw.SizedBox(height: 20),
      ],
    );
  }

  pw.Widget _buildPaginatedTable(List<Reservation> reservations) {
    return pw.TableHelper.fromTextArray(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.black,
      ),
      headerDecoration: const pw.BoxDecoration(
        color: PdfColors.grey200,
      ),
      cellHeight: 30,
      cellAlignments: {
        0: pw.Alignment.centerLeft,    // Book Title
        1: pw.Alignment.centerLeft,    // User Name
        2: pw.Alignment.center,        // Library ID
        3: pw.Alignment.center,        // Quantity
        4: pw.Alignment.center,        // Borrowed Date
        5: pw.Alignment.center,        // Return/Due Date
        6: pw.Alignment.center,        // Status
      },
      headers: [
        'Book Title',
        'User Name',
        'Library ID',
        'Quantity',
        'Borrowed Date',
        'Return/Due Date',
        'Status'
      ],
      data: reservations.map((res) => [
        res.bookTitle ?? 'Unknown',
        res.userName ?? 'Unknown',
        res.userLibraryNumber ?? 'N/A',
        res.quantity.toString(),
        res.formattedBorrowedDate,
        res.status == 'returned' && res.returnedDate != null
            ? _formatDate(res.returnedDate!.toDate())
            : res.formattedDueDate,
        res.currentStatus,
      ]).toList(),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),    // Book Title
        1: const pw.FlexColumnWidth(2.5),  // User Name
        2: const pw.FlexColumnWidth(1.5),  // Library ID
        3: const pw.FlexColumnWidth(1.0),  // Quantity
        4: const pw.FlexColumnWidth(1.8),  // Borrowed Date
        5: const pw.FlexColumnWidth(1.8),  // Return/Due Date
        6: const pw.FlexColumnWidth(1.5),  // Status
      },
    );
  }

  pw.Widget _buildSectionHeader(String title) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 14,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.blue900,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final DateFormat formatter = DateFormat('dd/MM/yyyy');
    return formatter.format(date);
  }

  pw.PageTheme _buildPageTheme() {
    return pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      theme: pw.ThemeData.withFont(
        base: pw.Font.helvetica(),
        bold: pw.Font.helveticaBold(),
      ),
      buildBackground: (context) => pw.Container(),
      margin: const pw.EdgeInsets.all(40),
    );
  }
} 