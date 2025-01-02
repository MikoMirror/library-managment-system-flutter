import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reservation.dart';
import '../../../core/repositories/base_repository.dart';
import 'dart:async';
import '../../../core/services/firestore/reservations_firestore_service.dart';
import '../../../core/services/firestore/books_firestore_service.dart';
import '../../../core/services/firestore/users_firestore_service.dart';

class ReservationsRepository implements BaseRepository {
  final ReservationsFirestoreService _reservationsService;
  final BooksFirestoreService _booksService;
  final UsersFirestoreService _usersService;
  Timer? _periodicCheckTimer;

  ReservationsRepository({
    required ReservationsFirestoreService reservationsService,
    required BooksFirestoreService booksService,
    required UsersFirestoreService usersService,
  })  : _reservationsService = reservationsService,
        _booksService = booksService,
        _usersService = usersService;

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
      
      final snapshot = await _reservationsService.getExpiredReservations(twentyFourHoursAgo);
      final batch = _reservationsService.batch();
      bool hasBatchOperations = false;

      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          final bookId = data['bookId'] as String;
          final quantity = data['quantity'] as int;
          
          // Update reservation status
          batch.update(doc.reference, {
            'status': 'expired',
            'updatedAt': now,
          });

          // Return books to inventory
          final bookRef = _booksService.getDocumentReference('books', bookId);
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
      final snapshot = await _reservationsService.getReservations();
      
      return Future.wait(snapshot.docs.map((doc) async {
        final data = doc.data();
        
        // Get book details
        final bookDoc = await _booksService
            .getDocumentReference(BooksFirestoreService.COLLECTION, data['bookId'] as String)
            .get();
        final bookData = bookDoc.data() as Map<String, dynamic>?;
        
        // Get user details
        final userDoc = await _reservationsService
            .getDocumentReference('users', data['userId'] as String)
            .get();
        final userData = userDoc.data() as Map<String, dynamic>?;

        return Reservation.fromMap({
          ...data,
          'bookTitle': bookData?['title'] as String?,
          'userName': userData?['name'] as String?,
          'userLibraryNumber': userData?['libraryNumber'] as String?,
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
    final batch = _reservationsService.batch();
    
    // Create the reservation data
    final reservationData = {
      'userId': userId,
      'bookId': bookId,
      'status': status,
      'borrowedDate': borrowedDate,
      'dueDate': dueDate,
      'quantity': quantity,
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    };

    // Use createReservation method instead of getDocumentReference
    final reservationRef = await _reservationsService.createReservation(reservationData);

    // Update the book quantity
    final bookRef = _booksService.getDocumentReference(BooksFirestoreService.COLLECTION, bookId);
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
      final batch = _reservationsService.batch();
      
      // Get the reservation document
      final reservationDoc = await _reservationsService
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

      // Update reservation status
      batch.update(reservationDoc.reference, {
        'status': newStatus,
        'updatedAt': Timestamp.now(),
        if (newStatus == 'returned') 'returnedDate': Timestamp.now(),
      });

      // Update book quantity when returning a book
      if (newStatus == 'returned' && oldStatus != 'returned') {
        final bookRef = _booksService.getDocumentReference('books', bookId);
        batch.update(bookRef, {
          'booksQuantity': FieldValue.increment(quantity),
        });
      }

      await batch.commit();
    } catch (e) {
      print('Error updating reservation status: $e');
      throw Exception('Failed to update reservation status: $e');
    }
  }

  Future<void> deleteReservation(String reservationId) async {
    try {
      // Get the reservation before deleting
      final reservationDoc = await _reservationsService
          .collection('books_reservation')
          .doc(reservationId)
          .get();

      if (!reservationDoc.exists) {
        throw Exception('Reservation not found');
      }

      final reservationData = reservationDoc.data()!;
      final status = reservationData['status'] as String;
      final bookId = reservationData['bookId'] as String;
      final quantity = reservationData['quantity'] as int;

      // Start a batch operation
      final batch = _reservationsService.batch();

      // Delete the reservation
      batch.delete(_reservationsService.collection('books_reservation').doc(reservationId));

      // Only update book quantity for active reservations
      if (['borrowed', 'reserved', 'overdue'].contains(status)) {
        final bookRef = _booksService.getDocumentReference('books', bookId);
        batch.update(bookRef, {
          'booksQuantity': FieldValue.increment(quantity),
        });
      }

      // Commit the batch
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete reservation: $e');
    }
  }

  Future<void> checkAndUpdateOverdueReservations() async {
    try {
      final now = Timestamp.now();
      
      // Get all borrowed books without date filter
      final snapshot = await _reservationsService
          .collection('books_reservation')
          .where('status', isEqualTo: 'borrowed')
          .get();

      final batch = _reservationsService.batch();
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
      final snapshot = await _reservationsService
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
      final snapshot = await _reservationsService
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
      final overdueSnapshot = await _reservationsService
          .collection('books_reservation')
          .where('status', isEqualTo: 'borrowed')
          .where('dueDate', isLessThanOrEqualTo: now)
          .get();

      // Update expired reservations
      final expiredSnapshot = await _reservationsService
          .collection('books_reservation')
          .where('status', isEqualTo: 'reserved')
          .where('borrowedDate', isLessThan: twentyFourHoursAgo)
          .get();

      final batch = _reservationsService.batch();
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

        final bookRef = _booksService.getDocumentReference('books', bookId);
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

  Future<bool> validateReservationDate(DateTime reservationDate) async {
    return await _reservationsService.validateReservationDate(reservationDate);
  }

  @override
  void dispose() {
    _periodicCheckTimer?.cancel();
    _periodicCheckTimer = null;
  }
}