import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking.dart';
import '../../../core/repositories/base_repository.dart';

class BookingsRepository implements BaseRepository {
  final FirebaseFirestore firestore;

  BookingsRepository({required this.firestore});

  Future<List<Booking>> getBookings() async {
    try {
      final snapshot = await firestore.collection('bookings').get();
      
      return Future.wait(snapshot.docs.map((doc) async {
        final data = doc.data();
        
        // Get book details
        final bookDoc = await firestore
            .collection('books')
            .doc(data['bookId'] as String)
            .get();
        final bookData = bookDoc.data();
        
        // Get user details
        final userDoc = await firestore
            .collection('users')
            .doc(data['userId'] as String)
            .get();
        final userData = userDoc.data();

        return Booking.fromMap({
          ...data,
          'bookTitle': bookData?['title'],
          'userName': userData?['name'],
          'userLibraryNumber': userData?['libraryNumber'],
        }, doc.id);
      }));
    } catch (e) {
      throw Exception('Failed to fetch bookings: $e');
    }
  }

  Future<void> createBooking({
    required String userId,
    required String bookId,
    required String status,
    required Timestamp borrowedDate,
    required Timestamp dueDate,
    required int quantity,
  }) async {
    final batch = firestore.batch();
    
    final bookingRef = firestore.collection('bookings').doc();
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

    final bookRef = firestore.collection('books').doc(bookId);
    batch.update(bookRef, {
      'booksQuantity': FieldValue.increment(-quantity),
    });

    await batch.commit();
  }

  Future<void> updateBookingStatus({
    required String bookingId,
    required String newStatus,
  }) async {
    try {
      final batch = firestore.batch();
      
      // Get the booking details
      final bookingDoc = await firestore.collection('bookings').doc(bookingId).get();
      final bookingData = bookingDoc.data();
      
      if (bookingData != null) {
        final bookId = bookingData['bookId'] as String;
        final quantity = bookingData['quantity'] as int;
        final oldStatus = bookingData['status'] as String;

        // Update booking status
        batch.update(
          firestore.collection('bookings').doc(bookingId),
          {
            'status': newStatus,
            'updatedAt': Timestamp.now(),
          },
        );

        // Handle book quantity updates
        if (newStatus == 'returned' && oldStatus != 'returned') {
          // Increment book quantity when returning
          batch.update(
            firestore.collection('books').doc(bookId),
            {'booksQuantity': FieldValue.increment(quantity)},
          );
        }

        await batch.commit();
      }
    } catch (e) {
      throw Exception('Failed to update booking status: $e');
    }
  }

  Future<void> deleteBooking(String bookingId) async {
    try {
      // Get the booking details before deletion
      final bookingDoc = await firestore.collection('bookings').doc(bookingId).get();
      final bookingData = bookingDoc.data();
      
      if (bookingData != null) {
        final status = bookingData['status'] as String;
        final bookId = bookingData['bookId'] as String;
        final quantity = bookingData['quantity'] as int;

        // Start a batch write
        final batch = firestore.batch();

        // Delete the booking
        batch.delete(firestore.collection('bookings').doc(bookingId));

        // If the booking was not returned, increment the book quantity
        if (status != 'returned') {
          final bookRef = firestore.collection('books').doc(bookId);
          batch.update(bookRef, {
            'booksQuantity': FieldValue.increment(quantity),
          });
        }

        // Commit the batch
        await batch.commit();
      }
    } catch (e) {
      throw Exception('Failed to delete booking: $e');
    }
  }

  @override
  void dispose() {
    // Clean up any resources if needed
  }
}