import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/book.dart';
import '../../../core/repositories/base_repository.dart';
import 'package:logger/logger.dart';

class BooksRepository implements BaseRepository {
  final FirebaseFirestore _firestore;
  final _logger = Logger();

  BooksRepository({required FirebaseFirestore firestore}) : _firestore = firestore;

  Future<void> addBook(Book book) async {
    await _firestore.collection('books').add(book.toMap());
  }

  Future<void> updateBook(Book book) async {
    if (book.id != null) {
      try {
        await _firestore.collection('books').doc(book.id).update(book.toMap());
      } catch (e) {
        throw Exception('Failed to update book: $e');
      }
    } else {
      throw Exception('Book ID is required for update');
    }
  }

  Future<void> deleteBook(String bookId) async {
    try {
      await _firestore.collection('books').doc(bookId).delete();
    } catch (e) {
      throw Exception('Failed to delete book: $e');
    }
  }

  Stream<List<Book>> getAllBooks() {
    return _firestore
        .collection('books')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Book.fromMap(
                  doc.data(),
                  doc.id,
                ))
            .toList());
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

  Future<void> rateBook(String bookId, String userId, double rating) async {
    await _firestore.collection('books').doc(bookId).update({
      'ratings.$userId': rating,
    });
  }

  Future<Map<String, double>> getBookRatings(String bookId) async {
    final doc = await _firestore.collection('books').doc(bookId).get();
    return Map<String, double>.from(doc.data()?['ratings'] ?? {});
  }

  Future<bool> getFavoriteStatus(String userId, String bookId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc(bookId)
          .get();
      return doc.exists;
    } catch (e) {
      _logger.e('Error getting favorite status:', error: e);
      rethrow;
    }
  }

  Future<void> toggleFavorite(String userId, String bookId) async {
    try {
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc(bookId);
      
      final doc = await docRef.get();
      if (doc.exists) {
        await docRef.delete();
      } else {
        await docRef.set({'timestamp': FieldValue.serverTimestamp()});
      }
    } catch (e) {
      _logger.e('Error toggling favorite:', error: e);
      rethrow;
    }
  }

  Stream<List<Book>> searchBooks(String query) {
    query = query.toLowerCase();
    return _firestore
        .collection('books')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Book.fromMap(doc.data(), doc.id))
            .where((book) =>
                book.title.toLowerCase().contains(query) ||
                book.author.toLowerCase().contains(query) ||
                book.isbn.toLowerCase().contains(query) ||
                book.categories.toLowerCase().contains(query))
            .toList());
  }

  @override
  void dispose() {
    // Clean up any resources if needed
  }
}