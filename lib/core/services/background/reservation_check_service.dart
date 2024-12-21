import 'dart:async';
import '../../../features/reservation/repositories/reservation_repository.dart';

class ReservationCheckService {
  final ReservationsRepository _repository;
  Timer? _timer;

  ReservationCheckService(this._repository);

  void startChecking() {
    // Check immediately when service starts
    _checkReservationStatuses();
    
    // Check every 2 hours
    _timer = Timer.periodic(const Duration(hours: 2), (_) {
      _checkReservationStatuses();
    });
  }

  Future<void> _checkReservationStatuses() async {
    try {
      // Check both overdue and expired reservations
      await _repository.checkAndUpdateOverdueReservations();
      await _repository.checkAndUpdateExpiredReservations();
    } catch (e) {
      print('Error checking reservation statuses: $e');
    }
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
} 