import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dashboard_state.dart';
import '../../../core/services/database/firestore_service.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final FirestoreService _firestoreService;

  DashboardCubit(this._firestoreService) : super(DashboardLoading());

  Future<void> loadDashboard() async {
    try {
      emit(DashboardLoading());

      // Get start date for trends (6 months ago by default)
      final startDate = DateTime.now().subtract(const Duration(days: 180));
      
      // Get all dashboard data
      final trends = await _firestoreService.getBorrowingTrends(startDate);
      final stats = await _firestoreService.getDashboardStats();

      emit(DashboardLoaded(
        uniqueBooks: stats['uniqueBooks']!,
        totalBooks: stats['totalBooks']!,
        reservedBooks: stats['reservedBooks']!,
        borrowedBooks: stats['borrowedBooks']!,
        overdueBooks: stats['overdueBooks']!,
        borrowingTrends: trends,
      ));
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }
} 