import 'package:flutter/material.dart';
import '../../models/book.dart';
import 'book_card.dart';
import '../../screens/book_info_screen.dart';
import '../../../../core/services/database/firestore_service.dart';
import 'book_card_mixin.dart';
import '../../../../features/users/models/user_model.dart';

class MobileBooksGrid extends StatefulWidget {
  final List<Book> books;
  final dynamic user;
  final Function(BuildContext, Book) onDeleteBook;

  MobileBooksGrid({
    super.key,
    required this.books,
    required this.user,
    required this.onDeleteBook,
  });

  @override
  State<MobileBooksGrid> createState() => _MobileBooksGridState();
}

class _MobileBooksGridState extends State<MobileBooksGrid> with BookCardMixin {
  String? get userId {
    if (widget.user is UserModel) {
      return (widget.user as UserModel).userId;
    }
    return widget.user.uid;
  }

  bool get isAdmin {
    if (widget.user is UserModel) {
      return (widget.user as UserModel).role == 'admin';
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: widget.books.length,
      addRepaintBoundaries: true,
      itemBuilder: (context, index) {
        final book = widget.books[index];
        return RepaintBoundary(
          child: buildBookCard(
            book: book,
            isMobile: true,
            isAdmin: isAdmin,
            userId: userId ?? '',
            onDeleteBook: widget.onDeleteBook,
            context: context,
          ),
        );
      },
    );
  }
} 