import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/book.dart';
import '../../../core/repositories/base_repository.dart';
import 'package:logger/logger.dart';
import '../../../core/services/firestore/books_firestore_service.dart';

class BooksRepository implements BaseRepository {
  final BooksFirestoreService _firestoreService;
  final _logger = Logger();
  static const String collectionPath = 'books';

  BooksRepository({
    required BooksFirestoreService firestoreService,
  }) : _firestoreService = firestoreService;

  Future<void> addBook(Book book) async {
    final bookData = book.toMap();
    bookData['createdAt'] = FieldValue.serverTimestamp();
    await _firestoreService.addDocument(collectionPath, bookData);
  }

  Stream<List<Book>> getAllBooks() {
    return _firestoreService.getCollectionStream(
      collection: collectionPath,
      fromMap: (data, id) => Book.fromMap(data, id),
    );
  }

  Stream<List<Book>> searchBooks(String query) {
    if (query.isEmpty) {
      return getAllBooks();
    }
    
    return _firestoreService.getCollectionStream(
      collection: collectionPath,
      fromMap: (data, id) => Book.fromMap(data, id),
    ).map((books) {
      final lowercaseQuery = query.toLowerCase();
      return books.where((book) => 
        book.title.toLowerCase().contains(lowercaseQuery) ||
        book.author.toLowerCase().contains(lowercaseQuery)
      ).toList();
    });
  }

  Future<void> deleteBook(String bookId) async {
    await _firestoreService.deleteDocument(collectionPath, bookId);
  }

  Future<void> updateBookQuantity(String bookId, int quantity) async {
    await _firestoreService.updateDocument(
      collectionPath, 
      bookId, 
      {'booksQuantity': quantity}
    );
  }

  Future<void> rateBook(String bookId, String userId, double rating) async {
    await _firestoreService.updateDocument(collectionPath, bookId, {
      'ratings.$userId': rating,
    });
  }

  Future<Map<String, double>> getBookRatings(String bookId) async {
    try {
      final doc = await _firestoreService.getDocument(collectionPath, bookId);
      final data = doc.data() as Map<String, dynamic>;
      final ratings = data['ratings'] as Map<String, dynamic>? ?? {};
      return Map<String, double>.fromEntries(
        ratings.entries.map(
          (entry) => MapEntry(
            entry.key, 
            (entry.value as num).toDouble(),
          ),
        ),
      );
    } catch (e) {
      _logger.e('Error getting book ratings:', error: e);
      return {};
    }
  }

  Future<bool> getFavoriteStatus(String userId, String bookId) async {
    try {
      final doc = await _firestoreService.getNestedDocument(
        'users', 
        userId, 
        'favorites', 
        bookId
      );
      return doc.exists;
    } catch (e) {
      _logger.e('Error getting favorite status:', error: e);
      rethrow;
    }
  }

  Future<void> toggleFavorite(String userId, String bookId) async {
    try {
      final docRef = _firestoreService.getNestedDocumentReference(
        'users', 
        userId, 
        'favorites', 
        bookId
      );
      
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

  Future<void> incrementBookQuantity(
    String bookId,
    int incrementBy,
    Transaction transaction,
  ) async {
    final bookRef = _firestoreService.getDocumentReference(collectionPath, bookId);
    final bookDoc = await transaction.get(bookRef);

    if (!bookDoc.exists) {
      throw Exception('Book not found');
    }

    final data = bookDoc.data() as Map<String, dynamic>;
    final currentQuantity = data['booksQuantity'] as int? ?? 0;
    
    transaction.update(bookRef, {
      'booksQuantity': currentQuantity + incrementBy,
    });
  }

  @override
  void dispose() {
    
  }
}