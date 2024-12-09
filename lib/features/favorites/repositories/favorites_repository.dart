import 'package:cloud_firestore/cloud_firestore.dart';
import '../../books/models/book.dart';
import 'dart:async';

class FavoritesRepository {
  final _firestore = FirebaseFirestore.instance;
  final _cache = <String, List<Book>>{};
  StreamController<List<Book>>? _controller;

  Stream<List<Book>> getFavoriteBooks(String userId) {
    // Return cached stream if exists
    _controller ??= StreamController<List<Book>>.broadcast();
    
    // Return cached data immediately if available
    if (_cache.containsKey(userId)) {
      _controller!.add(_cache[userId]!);
    }

    // Listen to favorites collection
    _firestore.collection('users').doc(userId).collection('favorites')
      .snapshots()
      .listen((snapshot) async {
        if (snapshot.docs.isEmpty) {
          _cache[userId] = [];
          _controller!.add([]);
          return;
        }

        // Batch fetch books
        final bookIds = snapshot.docs.map((doc) => doc.id).toList();
        final batchSize = 10;
        final books = <Book>[];

        for (var i = 0; i < bookIds.length; i += batchSize) {
          final end = (i + batchSize < bookIds.length) ? i + batchSize : bookIds.length;
          final batch = bookIds.sublist(i, end);
          
          final booksSnapshot = await _firestore.collection('books')
            .where(FieldPath.documentId, whereIn: batch)
            .get();

          books.addAll(
            booksSnapshot.docs.map((doc) => Book.fromMap(
              doc.data(), 
              doc.id,
            )),
          );
        }

        _cache[userId] = books;
        _controller!.add(books);
    });

    return _controller!.stream;
  }

  void dispose() {
    _controller?.close();
    _controller = null;
    _cache.clear();
  }
} 