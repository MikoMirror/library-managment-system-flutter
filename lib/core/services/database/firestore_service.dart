import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../features/books/models/book.dart';
import '../../../features/users/models/user_model.dart';
import 'package:intl/intl.dart';
import '../../../features/dashboard/models/borrowing_trend_point.dart';

class FirestoreService {
  static const String BOOKS_COLLECTION = 'books';
  static const String USERS_COLLECTION = 'users';
  static const String FAVORITES_COLLECTION = 'favorites';
  static const String RESERVATIONS_COLLECTION = 'books_reservation';

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
        .collection(USERS_COLLECTION)
        .doc(userId)
        .collection(FAVORITES_COLLECTION)
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
        .collection(RESERVATIONS_COLLECTION)
        .orderBy('borrowedDate', descending: true)
        .snapshots();
  }

  Future<String> getBookTitle(String bookId) async {
    final doc = await _firestore.collection(BOOKS_COLLECTION).doc(bookId).get();
    return doc.data()?['title'] ?? 'Unknown Book';
  }

  Future<String> getUserName(String userId) async {
    final doc = await _firestore.collection(USERS_COLLECTION).doc(userId).get();
    return doc.data()?['name'] ?? 'Unknown User';
  }

  Future<void> updateBookingStatus(String bookingId, String status) async {
    final batch = _firestore.batch();
    final bookingRef = _firestore.collection(RESERVATIONS_COLLECTION).doc(bookingId);

    final bookingDoc = await bookingRef.get();
    if (!bookingDoc.exists) {
      throw Exception('Booking not found');
    }

    final bookingData = bookingDoc.data()!;
    final bookId = bookingData['bookId'] as String;
    final quantity = bookingData['quantity'] as int;
    final oldStatus = bookingData['status'] as String;

    if (status == 'returned' || status == 'expired') {
      batch.update(bookingRef, {
        'status': status,
        'returnedDate': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      if (oldStatus != 'returned' && oldStatus != 'expired') {
        final bookRef = _firestore.collection(BOOKS_COLLECTION).doc(bookId);
        batch.update(bookRef, {
          'booksQuantity': FieldValue.increment(quantity),
        });
      }
    } else {
      batch.update(bookingRef, {
        'status': status,
        'updatedAt': Timestamp.now(),
      });
    }

    await batch.commit();
  }

  Future<void> deleteBooking(String bookingId) async {
    final bookingDoc = await _firestore
        .collection(RESERVATIONS_COLLECTION)
        .doc(bookingId)
        .get();
    
    if (!bookingDoc.exists) {
      throw Exception('Booking not found');
    }

    final data = bookingDoc.data()!;
    final status = data['status'] as String;
    final bookId = data['bookId'] as String;
    final quantity = data['quantity'] as int;

    final batch = _firestore.batch();

    batch.delete(bookingDoc.reference);

    if (status != 'returned' && status != 'expired') {
      final bookRef = _firestore.collection(BOOKS_COLLECTION).doc(bookId);
      batch.update(bookRef, {
        'booksQuantity': FieldValue.increment(quantity),
      });
    }

    await batch.commit();
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
    
    final bookingRef = _firestore.collection(RESERVATIONS_COLLECTION).doc();
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

    final bookRef = _firestore.collection(BOOKS_COLLECTION).doc(bookId);
    batch.update(bookRef, {
      'booksQuantity': FieldValue.increment(-quantity),
    });

    await batch.commit();
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
    
    if (_favoriteCache.containsKey(cacheKey)) {
      return _favoriteCache[cacheKey]!;
    }

    final stream = _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(bookId)
        .snapshots()
        .map((snapshot) => snapshot.exists)
        .distinct();

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

  Stream<DocumentSnapshot> getUserStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .handleError((error) {
      debugPrint('Error getting user data: $error');
      return error;
    });
  }

  Future<DocumentSnapshot> getUserData(String userId) async {
    try {
      return await _firestore.collection('users').doc(userId).get();
    } catch (e) {
      debugPrint('Error getting user data: $e');
      rethrow;
    }
  }

  Stream<QuerySnapshot> getBooksStream() {
    return _firestore
        .collection('books')
        .snapshots()
        .handleError((error) {
      debugPrint('Error getting books: $error');
      return error;
    });
  }

  Stream<DocumentSnapshot> getBookStream(String bookId) {
    return _firestore
        .collection('books')
        .doc(bookId)
        .snapshots()
        .handleError((error) {
      debugPrint('Error getting book: $error');
      return error;
    });
  }

  Future<void> createUserDocument(UserModel user) async {
    try {
      await _firestore
          .collection('users')
          .doc(user.userId)
          .set(user.toMap());
    } catch (e) {
      throw Exception('Failed to create user document: $e');
    }
  }

  Future<bool> checkUserExists(String email) async {
    final querySnapshot = await _firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .get();
    return querySnapshot.docs.isNotEmpty;
  }

  Future<void> deleteUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).delete();
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  Future<void> trackBorrowingEvent(String bookId) async {
    final now = DateTime.now();
    final dayKey = DateFormat('yyyy-MM-dd').format(now);
    
    await _firestore.collection('books').doc(bookId)
        .collection('borrowing_history')
        .doc(dayKey)
        .set({
          'timestamp': now,
          'count': FieldValue.increment(1),
        }, SetOptions(merge: true));
  }

  Future<List<BorrowingTrendPoint>> getBorrowingTrends(DateTime startDate) async {
    final snapshots = await _firestore
        .collectionGroup('borrowing_history')
        .where('timestamp', isGreaterThanOrEqualTo: startDate)
        .orderBy('timestamp')
        .get();

    final trendsMap = <String, int>{};
    for (var doc in snapshots.docs) {
      final timestamp = (doc.data()['timestamp'] as Timestamp).toDate();
      final dayKey = DateFormat('yyyy-MM-dd').format(timestamp);
      final count = doc.data()['count'] as int;
      
      trendsMap[dayKey] = (trendsMap[dayKey] ?? 0) + count;
    }

    return trendsMap.entries.map((entry) {
      return BorrowingTrendPoint(
        timestamp: DateFormat('yyyy-MM-dd').parse(entry.key),
        count: entry.value,
      );
    }).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  Future<Map<String, int>> getDashboardStats() async {
    final booksSnapshot = await _firestore.collection(BOOKS_COLLECTION).get();
    final reservationsSnapshot = await _firestore.collection(RESERVATIONS_COLLECTION).get();
    
    int uniqueBooks = booksSnapshot.docs.length;
    int totalBooks = 0;
    int reservedBooks = 0;
    int borrowedBooks = 0;
    int overdueBooks = 0;
    int expiredBooks = 0;

    for (var doc in booksSnapshot.docs) {
      final data = doc.data();
      totalBooks += (data['booksQuantity'] as int?) ?? 0;
    }

    for (var doc in reservationsSnapshot.docs) {
      final data = doc.data();
      final status = data['status'] as String?;
      
      switch (status) {
        case 'reserved':
          reservedBooks++;
          break;
        case 'borrowed':
          borrowedBooks++;
          break;
        case 'overdue':
          overdueBooks++;
          break;
        case 'expired':
          expiredBooks++;
          break;
      }
    }

    return {
      'uniqueBooks': uniqueBooks,
      'totalBooks': totalBooks,
      'reservedBooks': reservedBooks,
      'borrowedBooks': borrowedBooks,
      'overdueBooks': overdueBooks,
      'expiredBooks': expiredBooks,
    };
  }
}