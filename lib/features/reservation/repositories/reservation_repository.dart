import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reservation.dart';
import '../../../core/repositories/base_repository.dart';

class ReservationsRepository implements BaseRepository {
  final FirebaseFirestore firestore;

  ReservationsRepository({required this.firestore});

  Future<List<Reservation>> getReservations() async {
    try {
      final snapshot = await firestore.collection('books_reservation').get();
      
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

        return Reservation.fromMap({
          ...data,
          'bookTitle': bookData?['title'],
          'userName': userData?['name'],
          'userLibraryNumber': userData?['libraryNumber'],
        }, doc.id);
      }));
    } catch (e) {
      throw Exception('Failed to fetch reservations: $e');
    }
  }

  Future<void> createReservation({
    required String userId,
    required String bookId,
    required String status,
    required Timestamp borrowedDate,
    required Timestamp dueDate,
    required int quantity,
  }) async {
    final batch = firestore.batch();
    
    final reservationRef = firestore.collection('books_reservation').doc();
    batch.set(reservationRef, {
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

  Future<void> updateReservationStatus({
    required String reservationId,
    required String newStatus,
  }) async {
    try {
      final batch = firestore.batch();
      
      // Get the reservation details
      final reservationDoc = await firestore.collection('books_reservation').doc(reservationId).get();
      final reservationData = reservationDoc.data();
      
      if (reservationData != null) {
        final bookId = reservationData['bookId'] as String;
        final quantity = reservationData['quantity'] as int;
        final oldStatus = reservationData['status'] as String;

        // Update reservation status
        batch.update(
          firestore.collection('books_reservation').doc(reservationId),
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
      throw Exception('Failed to update reservation status: $e');
    }
  }

  Future<void> deleteReservation(String reservationId) async {
    try {
      // Get the reservation details before deletion
      final reservationDoc = await firestore.collection('books_reservation').doc(reservationId).get();
      final reservationData = reservationDoc.data();
      
      if (reservationData != null) {
        final status = reservationData['status'] as String;
        final bookId = reservationData['bookId'] as String;
        final quantity = reservationData['quantity'] as int;

        // Start a batch write
        final batch = firestore.batch();

        // Delete the reservation
        batch.delete(firestore.collection('books_reservation').doc(reservationId));

        // If the reservation was not returned, increment the book quantity
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
      throw Exception('Failed to delete reservation: $e');
    }
  }

  @override
  void dispose() {
    // Clean up any resources if needed
  }
}