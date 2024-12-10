import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking.dart';
import '../../../core/repositories/base_repository.dart';

class BookingsRepository implements BaseRepository {
  final FirebaseFirestore _firestore;

  BookingsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<QuerySnapshot> getAllBookings() {
    return _firestore
        .collection('bookings')
        .orderBy('borrowedDate', descending: true)
        .snapshots();
  }

  Future<void> createBooking({
    required String userId,
    required String bookId,
    required String status,
    required Timestamp borrowedDate,
    required Timestamp dueDate,
    required int quantity,
  }) async {
    final batch = _firestore.batch();
    
    // Create the booking document
    final bookingRef = _firestore.collection('bookings').doc();
    batch.set(bookingRef, {
      'userId': userId,
      'bookId': bookId,
      'status': status,
      'borrowedDate': borrowedDate,
      'dueDate': dueDate,
      'quantity': quantity,
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    });

    // Update book quantity
    final bookRef = _firestore.collection('books').doc(bookId);
    batch.update(bookRef, {
      'booksQuantity': FieldValue.increment(-quantity),
    });

    // Commit the batch
    await batch.commit();
  }

  Future<void> updateBookingStatus({
    required String bookingId,
    required String status,
  }) async {
    try {
      final batch = _firestore.batch();
      final bookingRef = _firestore.collection('bookings').doc(bookingId);
      
      // Get the booking to check if we need to update book quantity
      final bookingDoc = await bookingRef.get();
      final bookingData = bookingDoc.data() as Map<String, dynamic>;
      
      batch.update(bookingRef, {
        'status': status,
        'updatedAt': Timestamp.now(),
      });

      // If the book is being returned, update the book quantity
      if (status == 'returned') {
        final bookRef = _firestore.collection('books').doc(bookingData['bookId']);
        batch.update(bookRef, {
          'booksQuantity': FieldValue.increment(bookingData['quantity'] as int),
        });
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to update booking status: $e');
    }
  }

  Future<void> deleteBooking(String bookingId) async {
    final batch = _firestore.batch();
    
    // Get the booking to restore book quantity
    final bookingRef = _firestore.collection('bookings').doc(bookingId);
    final bookingDoc = await bookingRef.get();
    final bookingData = bookingDoc.data() as Map<String, dynamic>;
    
    // Only restore quantity if the booking was active
    if (bookingData['status'] != 'returned') {
      final bookRef = _firestore.collection('books').doc(bookingData['bookId']);
      batch.update(bookRef, {
        'booksQuantity': FieldValue.increment(bookingData['quantity'] as int),
      });
    }
    
    batch.delete(bookingRef);
    await batch.commit();
  }

  @override
  void dispose() {
    // Clean up any resources if needed
  }
}