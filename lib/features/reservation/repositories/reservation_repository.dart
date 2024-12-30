import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reservation.dart';
import '../../../core/repositories/base_repository.dart';
import 'dart:async';

class ReservationsRepository implements BaseRepository {
  final FirebaseFirestore firestore;
  Timer? _periodicCheckTimer;

  ReservationsRepository({required this.firestore});

  void startPeriodicCheck() {
    // Check immediately when service starts
    checkExpiredReservations();
    // Then check every hour
    _periodicCheckTimer = Timer.periodic(
      const Duration(hours: 1), 
      (_) => checkExpiredReservations()
    );
  }

  Future<void> checkExpiredReservations() async {
    try {
      final now = Timestamp.now();
      final twentyFourHoursAgo = Timestamp.fromDate(
        DateTime.now().subtract(const Duration(hours: 24))
      );
      
      // Simpler query that only checks status and borrowedDate
      final snapshot = await firestore
          .collection('books_reservation')
          .where('status', isEqualTo: 'reserved')
          .where('borrowedDate', isLessThan: twentyFourHoursAgo)
          .get();

      final batch = firestore.batch();
      bool hasBatchOperations = false;

      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          final bookId = data['bookId'] as String;
          final quantity = data['quantity'] as int;
          
          // Update reservation status
          batch.update(doc.reference, {
            'status': 'expired',
            'updatedAt': Timestamp.now(),
          });

          // Return books to inventory
          final bookRef = firestore.collection('books').doc(bookId);
          batch.update(bookRef, {
            'booksQuantity': FieldValue.increment(quantity),
          });

          hasBatchOperations = true;
        } catch (e) {
          print('Error processing reservation ${doc.id}: $e');
          continue;
        }
      }

      if (hasBatchOperations) {
        await batch.commit();
      }
    } catch (e) {
      print('Error checking reservation statuses: $e');
      throw Exception('Failed to check reservation statuses: $e');
    }
  }

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
    Transaction? transaction,
  }) async {
    final docRef = firestore.collection('books_reservation').doc(reservationId);
    
    final updateData = {
      'status': newStatus,
      'updatedAt': Timestamp.now(),
    };

    if (transaction != null) {
      transaction.update(docRef, updateData);
    } else {
      await docRef.update(updateData);
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
      final now = Timestamp.now();
      
      // Get all borrowed books without date filter
      final snapshot = await firestore
          .collection('books_reservation')
          .where('status', isEqualTo: 'borrowed')
          .get();

      final batch = firestore.batch();
      bool hasBatchOperations = false;

      // Filter in memory
      for (var doc in snapshot.docs) {
        final dueDate = doc.data()['dueDate'] as Timestamp;
        if (dueDate.compareTo(now) <= 0) {
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

  Future<List<Reservation>> getReservationsToExpire(DateTime now) async {
    try {
      final snapshot = await firestore
          .collection('books_reservation')
          .where('status', isEqualTo: 'reserved')
          .where('borrowedDate', isLessThan: Timestamp.fromDate(now))
          .get();

      return snapshot.docs
          .map((doc) => Reservation.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch reservations to expire: $e');
    }
  }

  Future<List<Reservation>> getBorrowedBooksToCheck(DateTime now) async {
    try {
      final snapshot = await firestore
          .collection('books_reservation')
          .where('status', isEqualTo: 'borrowed')
          .where('dueDate', isLessThan: Timestamp.fromDate(now))
          .get();

      return snapshot.docs
          .map((doc) => Reservation.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch borrowed books to check: $e');
    }
  }

  Future<void> resetAllReservationStatuses() async {
    try {
      final now = Timestamp.now();
      final twentyFourHoursAgo = Timestamp.fromDate(
        DateTime.now().subtract(const Duration(hours: 24))
      );
      
      // Update overdue reservations
      final overdueSnapshot = await firestore
          .collection('books_reservation')
          .where('status', isEqualTo: 'borrowed')
          .where('dueDate', isLessThanOrEqualTo: now)
          .get();

      // Update expired reservations
      final expiredSnapshot = await firestore
          .collection('books_reservation')
          .where('status', isEqualTo: 'reserved')
          .where('borrowedDate', isLessThan: twentyFourHoursAgo)
          .get();

      final batch = firestore.batch();
      bool hasBatchOperations = false;

      // Process overdue reservations
      for (var doc in overdueSnapshot.docs) {
        batch.update(doc.reference, {
          'status': 'overdue',
          'updatedAt': now,
        });
        hasBatchOperations = true;
      }

      // Process expired reservations
      for (var doc in expiredSnapshot.docs) {
        final data = doc.data();
        final bookId = data['bookId'] as String;
        final quantity = data['quantity'] as int;
        
        batch.update(doc.reference, {
          'status': 'expired',
          'updatedAt': now,
        });

        final bookRef = firestore.collection('books').doc(bookId);
        batch.update(bookRef, {
          'booksQuantity': FieldValue.increment(quantity),
        });
        
        hasBatchOperations = true;
      }

      if (hasBatchOperations) {
        await batch.commit();
      }
    } catch (e) {
      throw Exception('Failed to reset reservation statuses: $e');
    }
  }

  @override
  void dispose() {
    _periodicCheckTimer?.cancel();
  }
}