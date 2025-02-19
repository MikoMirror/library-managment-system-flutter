import 'package:flutter/material.dart';
import '../../models/book.dart';
import 'book_card.dart';

class MobileBooksGrid extends StatelessWidget {
  final List<Book> books;
  final bool isAdmin;
  final String? userId;
  final Function(BuildContext, Book)? onDeleteBook;
  final bool showAdminControls;

  const MobileBooksGrid({
    super.key,
    required this.books,
    required this.userId,
    required this.isAdmin,
    required this.onDeleteBook,
    this.showAdminControls = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemExtent: 160.0,
      itemCount: books.length,
      itemBuilder: (context, index) {
        return RepaintBoundary(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: BookCard(
              key: ValueKey(books[index].id),
              book: books[index],
              isMobile: true,
              isAdmin: isAdmin,
              userId: userId,
              showAdminControls: showAdminControls,
              onDelete: onDeleteBook != null 
                  ? () => onDeleteBook!(context, books[index])
                  : null,
            ),
          ),
        );
      },
    );
  }
}