import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reservation.dart';
import '../../../core/repositories/base_repository.dart';
import 'dart:async';
import '../../../core/services/firestore/reservations_firestore_service.dart';
import '../../../core/services/firestore/books_firestore_service.dart';
import 'package:logger/logger.dart';
import '../../../core/services/firestore/users_firestore_service.dart';

class ReservationsRepository implements BaseRepository {
  final ReservationsFirestoreService _reservationsService;
  final BooksFirestoreService _booksService;
  final UsersFirestoreService _usersService;
  final _logger = Logger();
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

          // Check if book exists before updating quantity
          try {
            final bookDoc = await _booksService.getDocument(
              BooksFirestoreService.collectionPath,
              bookId,
            );

            if (bookDoc.exists) {
              final bookRef = _booksService.getDocumentReference('books', bookId);
              batch.update(bookRef, {
                'booksQuantity': FieldValue.increment(quantity),
              });
            } else {
              _logger.w('Book not found while processing expired reservation: $bookId');
            }
          } catch (e) {
            _logger.w('Error checking book existence: $e');
            // Continue with reservation update even if book check fails
          }

          hasBatchOperations = true;
        } catch (e) {
          _logger.e('Error processing reservation ${doc.id}: $e');
          continue;
        }
      }

      if (hasBatchOperations) {
        await batch.commit();
      }
    } catch (e) {
      _logger.e('Error checking reservation statuses: $e');
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
            .getDocumentReference(BooksFirestoreService.collectionPath, data['bookId'] as String)
            .get();
        final bookData = bookDoc.data();
        
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
    await _reservationsService.createReservation(reservationData);

    // Update the book quantity
    final bookRef = _booksService.getDocumentReference(BooksFirestoreService.collectionPath, bookId);
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
      final reservationDoc = await _reservationsService
          .collection('books_reservation')
          .doc(reservationId)
          .get();
      final reservationData = reservationDoc.data();
      
      if (reservationData == null) {
        throw Exception('Reservation not found');
      }

      final batch = _reservationsService.batch();
      
      // Update reservation status
      batch.update(reservationDoc.reference, {
        'status': newStatus,
        'updatedAt': Timestamp.now(),
      });

      // If canceling, return the book quantity
      if (newStatus == 'canceled') {
        final bookId = reservationData['bookId'] as String;
        final quantity = reservationData['quantity'] as int;
        
        final bookRef = _booksService.getDocumentReference(
          BooksFirestoreService.collectionPath, 
          bookId
        );
        batch.update(bookRef, {
          'booksQuantity': FieldValue.increment(quantity),
        });
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to update reservation status: $e');
    }
  }

  Future<void> deleteReservation(String reservationId) async {
    try {
      // Get the reservation details first
      final reservationDoc = await _reservationsService
          .getDocument(ReservationsFirestoreService.collectionPath, reservationId);
      final reservationData = reservationDoc.data() as Map<String, dynamic>?;

      if (reservationData == null) {
        throw Exception('Reservation not found');
      }

      final bookId = reservationData['bookId'] as String;
      final quantity = reservationData['quantity'] as int;
      final status = reservationData['status'] as String;

      // Start a batch operation
      final batch = _reservationsService.batch();

      // Delete the reservation
      batch.delete(_reservationsService.getDocumentReference(
        ReservationsFirestoreService.collectionPath,
        reservationId,
      ));

      // Only update book quantity if status is 'reserved' or 'borrowed'
      // and the book still exists in the library
      if ((status == 'reserved' || status == 'borrowed')) {
        try {
          final bookDoc = await _booksService.getDocument(
            BooksFirestoreService.collectionPath,
            bookId,
          );

          // Only update quantity if book exists
          if (bookDoc.exists) {
            final bookRef = _booksService.getDocumentReference(
              BooksFirestoreService.collectionPath,
              bookId,
            );
            batch.update(bookRef, {
              'booksQuantity': FieldValue.increment(quantity),
            });
          }
        } catch (e) {
          _logger.w('Book not found while deleting reservation: $bookId');
          // Continue with reservation deletion even if book is not found
        }
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

  Future<void> updateBookQuantity(String bookId, int quantity) async {
    try {
      await _booksService.updateDocument(
        BooksFirestoreService.collectionPath,
        bookId,
        {'booksQuantity': FieldValue.increment(quantity)}
      );
    } catch (e) {
      throw Exception('Failed to update book quantity: $e');
    }
  }

  @override
  void dispose() {
    _periodicCheckTimer?.cancel();
    _periodicCheckTimer = null;
  }
}