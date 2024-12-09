import 'package:flutter/material.dart';
import '../../models/book.dart';
import 'book_card.dart';

class MobileBooksGrid extends StatelessWidget {
  final List<Book> books;
  final bool isAdmin;
  final String? userId;
  final Function(BuildContext, Book)? onDeleteBook;

  const MobileBooksGrid({
    super.key,
    required this.books,
    this.isAdmin = false,
    this.userId,
    this.onDeleteBook,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: books.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: BookCard(
            book: books[index],
            isMobile: true,
            isAdmin: isAdmin,
            userId: userId,
            onDelete: onDeleteBook != null 
                ? () => onDeleteBook!(context, books[index])
                : null,
          ),
        );
      },
    );
  }
}