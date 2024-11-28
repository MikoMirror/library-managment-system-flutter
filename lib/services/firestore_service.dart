import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/book.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addBook(String collectionId, Book book) async {
    await _firestore.collection(collectionId).add(book.toMap());
  }

  Future<void> updateBook(String collectionId, Book book) async {
    if (book.id != null) {
      try {
        await _firestore
            .collection(collectionId)
            .doc(book.id)
            .update(book.toMap());
      } catch (e) {
        throw Exception('Failed to update book: $e');
      }
    } else {
      throw Exception('Book ID is required for update');
    }
  }

  Future<void> deleteBook(String collectionId, String bookId) async {
    try {
      await _firestore.collection(collectionId).doc(bookId).delete();
    } catch (e) {
      throw Exception('Failed to delete book: $e');
    }
  }

  Future<void> toggleFavorite(String userId, String bookId) async {
    final userFavRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(bookId);

    final doc = await userFavRef.get();
    if (doc.exists) {
      await userFavRef.delete();
    } else {
      await userFavRef.set({
        'addedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Stream<bool> isBookFavorited(String userId, String bookId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(bookId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  Stream<QuerySnapshot> getUserFavorites(String userId) {
    try {
      return _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .snapshots();
    } catch (e) {
      print('Error getting user favorites: $e');
      // Return an empty stream
      return Stream.empty();
    }
  }

  Stream<QuerySnapshot> getAllBookings() {
    try {
      return _firestore
          .collection('bookings')
          .orderBy('createdAt', descending: true)
          .snapshots();
    } catch (e) {
      print('Error getting bookings: $e');
      // Return an empty stream
      return Stream.empty();
    }
  }

  Future<String> getBookTitle(String bookId) async {
    final doc = await _firestore.collection('books').doc(bookId).get();
    return doc.data()?['title'] ?? 'Unknown Book';
  }

  Future<String> getUserName(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    return doc.data()?['name'] ?? 'Unknown User';
  }

  Future<void> updateBookingStatus(String bookingId, String status) async {
    await _firestore.collection('bookings').doc(bookingId).update({
      'status': status,
    });
  }

  Future<void> deleteBooking(String bookingId) async {
    await _firestore.collection('bookings').doc(bookingId).delete();
  }

  Future<void> createBooking({
    required String userId,
    required String bookId,
    required String status,
    required Timestamp borrowedDate,
    required Timestamp dueDate,
    required int quantity,
  }) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final bookRef = _firestore.collection('books').doc(bookId);
        final bookDoc = await transaction.get(bookRef);
        
        if (!bookDoc.exists) {
          throw Exception('Book not found');
        }

        final currentQuantity = bookDoc.data()?['booksQuantity'] ?? 0;
        if (currentQuantity < quantity) {
          throw Exception('Not enough books available');
        }

        final bookingRef = _firestore.collection('bookings').doc();
        transaction.set(bookingRef, {
          'userId': userId,
          'bookId': bookId,
          'status': status,
          'borrowedDate': borrowedDate,
          'dueDate': dueDate,
          'quantity': quantity,
          'createdAt': FieldValue.serverTimestamp(),
        });

        transaction.update(bookRef, {
          'booksQuantity': currentQuantity - quantity,
        });
      }, maxAttempts: 3);
    } catch (e) {
      throw Exception('Failed to create booking: $e');
    }
  }

  Stream<QuerySnapshot> getUsers() {
    return _firestore.collection('users').snapshots();
  }

  Future<void> updateBookQuantity(String bookId, int quantity) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final bookRef = _firestore.collection('books').doc(bookId);
        final bookDoc = await transaction.get(bookRef);
        
        if (!bookDoc.exists) {
          throw Exception('Book not found');
        }

        final currentQuantity = bookDoc.data()?['booksQuantity'] ?? 0;
        if (currentQuantity < quantity) {
          throw Exception('Not enough books available');
        }

        await transaction.update(bookRef, {
          'booksQuantity': currentQuantity - quantity,
        });
      }, maxAttempts: 3);
    } catch (e) {
      throw Exception('Failed to update book quantity: $e');
    }
  }
}