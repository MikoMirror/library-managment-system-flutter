import 'package:flutter/material.dart';
import '../../models/book.dart';
import '../../screens/book_info_screen.dart';
import '../../../../core/services/database/firestore_service.dart';
import 'book_card.dart';

mixin BookCardMixin {
  void handleBookTap(BuildContext context, Book book) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookInfoScreen(book: book),
      ),
    );
  }

  Future<void> handleFavoriteToggle(String userId, String bookId) async {
    await FirestoreService().toggleFavorite(userId, bookId);
  }

  Widget buildBookCard({
    required Book book,
    required bool isMobile,
    required bool isAdmin,
    required String userId,
    required Function(BuildContext, Book) onDeleteBook,
    required BuildContext context,
  }) {
    return StreamBuilder<bool>(
      stream: FirestoreService().getFavoriteStatus(userId, book.id!),
      builder: (context, snapshot) {
        final isFavorite = snapshot.data ?? false;
        
        return BookCard(
          book: book,
          isMobile: isMobile,
          isAdmin: isAdmin,
          userId: userId,
          initialFavoriteStatus: isFavorite,
          onTap: () => handleBookTap(context, book),
          onFavoriteToggle: isAdmin ? null : (isFavorite) async {
            await handleFavoriteToggle(userId, book.id!);
          },
          onDelete: isAdmin ? () => onDeleteBook(context, book) : null,
        );
      },
    );
  }
} 