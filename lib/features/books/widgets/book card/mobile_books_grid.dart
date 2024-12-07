import 'package:flutter/material.dart';
import '../../models/book.dart';
import 'book_card.dart';
import '../../screens/book_info_screen.dart';
import '../../../../core/services/database/firestore_service.dart';
import 'book_card_mixin.dart';
import '../../../../features/users/models/user_model.dart';

class MobileBooksGrid extends StatelessWidget with BookCardMixin {
  final List<Book> books;
  final dynamic user;  // This will be either UserModel or Firebase User
  final Function(BuildContext, Book) onDeleteBook;

  const MobileBooksGrid({
    super.key,
    required this.books,
    required this.user,
    required this.onDeleteBook,
  });

  String? get userId {
    if (user is UserModel) {
      return (user as UserModel).userId;
    }
    return user.uid;
  }

  bool get isAdmin {
    if (user is UserModel) {
      return (user as UserModel).role == 'admin';
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: books.length,
      addRepaintBoundaries: true,
      itemBuilder: (context, index) {
        final book = books[index];
        return RepaintBoundary(
          child: KeyedSubtree(
            key: ValueKey('book-${book.id}'),
            child: buildBookCard(
              book: book,
              isMobile: true,
              isAdmin: isAdmin,
              userId: userId ?? '',
              onDeleteBook: onDeleteBook,
              context: context,
            ),
          ),
        );
      },
    );
  }
} 