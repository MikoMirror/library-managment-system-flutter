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
    required String status,
  }) async {
    await firestore.collection('bookings').doc(bookingId).update({
      'status': status,
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> deleteBooking(String bookingId) async {
    await firestore.collection('bookings').doc(bookingId).delete();
  }

  @override
  void dispose() {
    // Clean up any resources if needed
  }
}