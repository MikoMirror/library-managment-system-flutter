import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking.dart';
import '../../../core/repositories/base_repository.dart';

class BookingsRepository implements BaseRepository {
  final FirebaseFirestore _firestore;

  BookingsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<QuerySnapshot> getAllBookings() {
    return _firestore.collection('bookings').snapshots();
  }

  Future<void> createBooking({
    required String userId,
    required String bookId,
    required String status,
    required Timestamp borrowedDate,
    required Timestamp dueDate,
    required int quantity,
  }) async {
    await _firestore.collection('bookings').add({
      'userId': userId,
      'bookId': bookId,
      'status': status,
      'borrowedDate': borrowedDate,
      'dueDate': dueDate,
      'quantity': quantity,
    });
  }

  Future<void> updateBookingStatus(String bookingId, String status) async {
    await _firestore.collection('bookings').doc(bookingId).update({
      'status': status,
    });
  }

  Future<void> deleteBooking(String bookingId) async {
    await _firestore.collection('bookings').doc(bookingId).delete();
  }

  @override
  void dispose() {
    // Clean up any resources if needed
  }
} 