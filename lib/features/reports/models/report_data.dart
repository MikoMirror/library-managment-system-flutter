import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:library_management_system/features/reservation/models/reservation.dart';

class ReportData {
  final DateTime startDate;
  final DateTime endDate;
  final int totalBorrowed;
  final int totalReturned;
  final List<Reservation> reservations;

  ReportData({
    required this.startDate,
    required this.endDate,
    required this.totalBorrowed,
    required this.totalReturned,
    required this.reservations,
  });
} 