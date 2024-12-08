import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../features/books/models/book.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final _favoriteCache = <String, Stream<bool>>{};

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

  Stream<bool> isBookFavorited(String userId, String bookId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(bookId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  Future<void> toggleFavorite(String userId, String bookId) async {
    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(bookId);

    final doc = await docRef.get();
    if (doc.exists) {
      await docRef.delete();
    } else {
      await docRef.set({'favorite': true});
    }
  }

  Stream<QuerySnapshot> getUserFavorites(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .snapshots();
  }

  Stream<QuerySnapshot> getAllBookings() {
    return _firestore
        .collection('bookings')
        .orderBy('borrowedDate', descending: true)
        .snapshots();
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
    await _firestore.collection('bookings').add({
      'userId': userId,
      'bookId': bookId,
      'status': status,
      'borrowedDate': borrowedDate,
      'dueDate': dueDate,
      'quantity': quantity,
    });
  }

  Stream<QuerySnapshot> getUsers() {
    return _firestore.collection('users').snapshots();
  }

  Future<void> updateBookQuantity(String bookId, int quantity) async {
    final bookRef = _firestore.collection('books').doc(bookId);
    
    return _firestore.runTransaction((transaction) async {
      final bookDoc = await transaction.get(bookRef);
      if (!bookDoc.exists) {
        throw Exception('Book not found');
      }

      final currentQuantity = bookDoc.data()?['availableQuantity'] ?? 0;
      if (currentQuantity < quantity) {
        throw Exception('Not enough books available');
      }

      transaction.update(bookRef, {
        'availableQuantity': currentQuantity - quantity,
      });
    });
  }

  Stream<bool> getFavoriteStatus(String userId, String bookId) {
    final cacheKey = '$userId-$bookId';
    
    // Return cached stream if it exists
    if (_favoriteCache.containsKey(cacheKey)) {
      return _favoriteCache[cacheKey]!;
    }

    // Create and cache new stream
    final stream = _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(bookId)
        .snapshots()
        .map((snapshot) => snapshot.exists)
        .distinct(); // Only emit when value changes

    _favoriteCache[cacheKey] = stream;
    return stream;
  }

  Future<void> updateBookRating(String bookId, String userId, double rating) async {
    final bookRef = _firestore.collection('books').doc(bookId);
    
    await bookRef.update({
      'ratings.$userId': rating,
    });
  }

  Future<Map<String, double>> getBookRatings(String bookId) async {
    final bookDoc = await _firestore.collection('books').doc(bookId).get();
    final data = bookDoc.data();
    
    if (data == null || !data.containsKey('ratings')) {
      return {};
    }

    final ratings = Map<String, double>.from(data['ratings'] as Map);
    return ratings;
  }
}