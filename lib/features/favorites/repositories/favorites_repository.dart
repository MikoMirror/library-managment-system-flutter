import 'package:cloud_firestore/cloud_firestore.dart';
import '../../books/models/book.dart';
import 'dart:async';

class FavoritesRepository {
  final _firestore = FirebaseFirestore.instance;
  final _cache = <String, List<Book>>{};
  final _controllers = <String, StreamController<List<Book>>>{};

  Stream<List<Book>> getFavoriteBooks(String userId) {
    // Create a new controller if it doesn't exist for this user
    if (!_controllers.containsKey(userId)) {
      _controllers[userId] = StreamController<List<Book>>.broadcast();
      
      // Set up the stream listener
      _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .snapshots()
          .listen((snapshot) async {
        try {
          if (snapshot.docs.isEmpty) {
            _cache[userId] = [];
            _controllers[userId]?.add([]);
            return;
          }

          // Get all book IDs from favorites
          final bookIds = snapshot.docs.map((doc) => doc.id).toList();
          final books = <Book>[];

          // Batch fetch books in groups of 10
          for (var i = 0; i < bookIds.length; i += 10) {
            final end = (i + 10 < bookIds.length) ? i + 10 : bookIds.length;
            final batch = bookIds.sublist(i, end);

            final booksSnapshot = await _firestore
                .collection('books')
                .where(FieldPath.documentId, whereIn: batch)
                .get();

            books.addAll(
              booksSnapshot.docs
                  .map((doc) => Book.fromMap(doc.data(), doc.id))
                  .where((book) => book != null) // Filter out null books
                  .cast<Book>(), // Cast to non-null Book
            );
          }

          _cache[userId] = books;
          _controllers[userId]?.add(books);
        } catch (e) {
          _controllers[userId]?.addError(e);
        }
      });
    }

    // Return cached data immediately if available
    if (_cache.containsKey(userId)) {
      _controllers[userId]?.add(_cache[userId]!);
    }

    return _controllers[userId]!.stream;
  }

  void dispose() {
    for (var controller in _controllers.values) {
      controller.close();
    }
    _controllers.clear();
    _cache.clear();
  }

  // Helper method to check if a book is in favorites
  Future<bool> isBookFavorite(String userId, String bookId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc(bookId)
          .get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  // Add a book to favorites
  Future<void> addToFavorites(String userId, String bookId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc(bookId)
          .set({
        'addedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Remove a book from favorites
  Future<void> removeFromFavorites(String userId, String bookId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc(bookId)
          .delete();
    } catch (e) {
      rethrow;
    }
  }
} 