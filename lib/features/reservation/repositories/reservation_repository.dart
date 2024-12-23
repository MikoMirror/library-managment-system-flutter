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
      // Get the reservation details first
      final reservationDoc = await firestore
          .collection('books_reservation')
          .doc(reservationId)
          .get();
      
      if (!reservationDoc.exists) {
        throw Exception('Reservation not found');
      }

      final reservationData = reservationDoc.data()!;
      final bookId = reservationData['bookId'] as String;
      final quantity = reservationData['quantity'] as int;
      final oldStatus = reservationData['status'] as String;

      // Start a batch write
      final batch = firestore.batch();
      final reservationRef = firestore.collection('books_reservation').doc(reservationId);
      final bookRef = firestore.collection('books').doc(bookId);

      // Update reservation status
      if (newStatus == 'returned') {
        batch.update(reservationRef, {
          'status': newStatus,
          'returnedDate': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        });

        // Only increase book quantity if the status wasn't already 'returned'
        if (oldStatus != 'returned') {
          // Increase available books quantity
          batch.update(bookRef, {
            'booksQuantity': FieldValue.increment(quantity),
          });
        }
      } else {
        batch.update(reservationRef, {
          'status': newStatus,
          'updatedAt': Timestamp.now(),
        });
      }

      await batch.commit();
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

  Future<void> checkAndUpdateOverdueReservations() async {
    try {
      final snapshot = await firestore
          .collection('books_reservation')
          .where('status', isEqualTo: 'borrowed')
          .get();

      final now = Timestamp.now();
      final batch = firestore.batch();
      bool hasBatchOperations = false;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final dueDate = data['dueDate'] as Timestamp;
        
        if (now.seconds > dueDate.seconds) {
          batch.update(doc.reference, {
            'status': 'overdue',
            'updatedAt': now,
          });
          hasBatchOperations = true;
        }
      }

      if (hasBatchOperations) {
        await batch.commit();
      }
    } catch (e) {
      throw Exception('Failed to update overdue reservations: $e');
    }
  }

  Future<void> checkAndUpdateExpiredReservations() async {
    try {
      final snapshot = await firestore
          .collection('books_reservation')
          .where('status', isEqualTo: 'reserved')
          .get();

      final now = Timestamp.now();
      final batch = firestore.batch();
      bool hasBatchOperations = false;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final borrowedDate = data['borrowedDate'] as Timestamp;
        
        // Check if more than 24 hours have passed
        if (now.seconds - borrowedDate.seconds > 24 * 60 * 60) {
          final bookId = data['bookId'] as String;
          final quantity = data['quantity'] as int;

          batch.update(doc.reference, {
            'status': 'expired',
            'updatedAt': now,
          });

          // Return books to inventory
          final bookRef = firestore.collection('books').doc(bookId);
          batch.update(bookRef, {
            'booksQuantity': FieldValue.increment(quantity),
          });

          hasBatchOperations = true;
        }
      }

      if (hasBatchOperations) {
        await batch.commit();
      }
    } catch (e) {
      throw Exception('Failed to update expired reservations: $e');
    }
  }

  @override
  void dispose() {
    // Clean up any resources if needed
  }
}