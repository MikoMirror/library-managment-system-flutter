import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/book.dart';
import '../../../core/repositories/base_repository.dart';

class BooksRepository implements BaseRepository {
  final FirebaseFirestore _firestore;

  BooksRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

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

  Stream<QuerySnapshot> getAllBooks() {
    return _firestore.collection('books').snapshots();
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

  @override
  void dispose() {
    // Clean up any resources if needed
  }
}