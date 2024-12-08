import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/book.dart';
import '../../screens/book_info_screen.dart';
import '../../../../core/services/database/firestore_service.dart';
import '../../../../core/services/image/image_cache_service.dart';
import '../../../books/widgets/book card/desktop_books_grid.dart';
import '../../../books/widgets/book card/mobile_books_grid.dart';
import 'book_card.dart';
import 'dart:async';

mixin BookCardMixin<T extends StatefulWidget> on State<T> {
  final ImageCacheService _imageCacheService = ImageCacheService();
  final Map<String, StreamController<bool>> _favoriteControllers = {};
  final FirestoreService _firestoreService = FirestoreService();
  bool _mounted = false;

  @override
  void initState() {
    super.initState();
    _mounted = true;
    _preCacheBookImages();
  }

  Future<void> _preCacheBookImages() async {
    List<Book>? books;
    
    if (widget is DesktopBooksGrid) {
      books = (widget as DesktopBooksGrid).books;
    } else if (widget is MobileBooksGrid) {
      books = (widget as MobileBooksGrid).books;
    }

    if (books != null) {
      await _imageCacheService.preCacheBookImages(context, books);
    }
  }

  @override
  void dispose() {
    _mounted = false;
    _cleanupControllers();
    super.dispose();
  }

  void _cleanupControllers() {
    for (var controller in _favoriteControllers.values) {
      if (!controller.isClosed) {
        controller.close();
      }
    }
    _favoriteControllers.clear();
  }

  Stream<bool> getFavoriteStream(String userId, String bookId) {
    final key = '$userId-$bookId';
    if (!_favoriteControllers.containsKey(key)) {
      final controller = StreamController<bool>.broadcast();
      _favoriteControllers[key] = controller;

      // Ensure platform thread usage
      scheduleMicrotask(() {
        if (_mounted) {
          _firestoreService.getFavoriteStatus(userId, bookId)
              .distinct()
              .listen(
                (status) {
                  if (_mounted && !controller.isClosed) {
                    controller.add(status);
                  }
                },
                onError: (error) {
                  if (_mounted && !controller.isClosed) {
                    controller.addError(error);
                  }
                },
                cancelOnError: false,
              );
        }
      });
    }
    return _favoriteControllers[key]!.stream;
  }

  // Clean up and recreate streams when layout changes
  void handleLayoutChange() {
    if (_mounted) {
      scheduleMicrotask(() {
        if (_mounted) {
          _cleanupControllers();
          setState(() {}); // Trigger rebuild with new streams
        }
      });
    }
  }

  Widget buildBookCard({
    required Book book,
    required bool isMobile,
    required bool isAdmin,
    required String userId,
    required Function(BuildContext, Book) onDeleteBook,
    required BuildContext context,
  }) {
    if (isAdmin) {
      return BookCard(
        key: ValueKey('admin-book-${book.id}'),
        book: book,
        isMobile: isMobile,
        isAdmin: isAdmin,
        userId: userId,
        initialFavoriteStatus: false,
        onTap: () => handleBookTap(context, book),
        onDelete: () => onDeleteBook(context, book),
      );
    }

    return StreamBuilder<bool>(
      key: ValueKey('stream-${book.id}'),
      stream: getFavoriteStream(userId, book.id!),
      builder: (context, snapshot) {
        return BookCard(
          key: ValueKey('user-book-${book.id}'),
          book: book,
          isMobile: isMobile,
          isAdmin: isAdmin,
          userId: userId,
          initialFavoriteStatus: snapshot.data ?? false,
          onTap: () => handleBookTap(context, book),
          onFavoriteToggle: (isFavorite) async {
            await handleFavoriteToggle(userId, book.id!);
          },
        );
      },
    );
  }

  void handleBookTap(BuildContext context, Book book) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookInfoScreen(book: book),
      ),
    );
  }

  Future<void> handleFavoriteToggle(String userId, String bookId) async {
    await _firestoreService.toggleFavorite(userId, bookId);
  }
}
