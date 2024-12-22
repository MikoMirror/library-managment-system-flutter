import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dashboard_state.dart';
import '../../../core/services/database/firestore_service.dart';
import 'dart:developer' as developer;
import 'dart:developer';
import 'dart:io';
import 'package:flutter/foundation.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final FirestoreService _firestoreService;

  DashboardCubit(this._firestoreService) : super(DashboardInitial(
    selectedStartDate: DateTime.now().subtract(const Duration(days: 29)),
    selectedEndDate: DateTime.now(),
  ));

  Future<void> loadDashboard({DateTime? startDate, DateTime? endDate}) async {
    try {
      final now = DateTime.now();
      final effectiveStartDate = startDate ?? 
          (state is DashboardInitial ? now.subtract(const Duration(days: 29)) : state.selectedStartDate);
      final effectiveEndDate = endDate ?? 
          (state is DashboardInitial ? now : state.selectedEndDate);

      emit(DashboardLoading(
        startDate: effectiveStartDate,
        endDate: effectiveEndDate,
      ));

      final stats = await _firestoreService.getDashboardStats();
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
        e.toString(),
        startDate: state.selectedStartDate,
        endDate: state.selectedEndDate,
      ));
    }
  }
} 