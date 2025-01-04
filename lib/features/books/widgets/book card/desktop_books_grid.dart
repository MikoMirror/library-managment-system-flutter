import 'package:flutter/material.dart';
import '../../models/book.dart';
import 'book_card.dart';


class DesktopBooksGrid extends StatelessWidget {
  final List<Book> books;
  final String userId;
  final bool isAdmin;
  final Function(BuildContext, Book) onDeleteBook;
  final bool showAdminControls;

  const DesktopBooksGrid({
    super.key,
    required this.books,
    required this.userId,
    required this.isAdmin,
    required this.onDeleteBook,
    this.showAdminControls = true,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = _calculateColumns(constraints.maxWidth);
        final aspectRatio = _calculateAspectRatio(constraints.maxWidth);

        return GridView.builder(
          padding: EdgeInsets.symmetric(
            horizontal: _calculatePadding(constraints.maxWidth),
            vertical: 16,
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: aspectRatio,
            crossAxisSpacing: 16,
            mainAxisSpacing: 24,
          ),
          itemCount: books.length,
          itemBuilder: (context, index) {
            return BookCard(
              book: books[index],
              isMobile: false,
              isAdmin: isAdmin,
              userId: userId,
              showAdminControls: showAdminControls,
              onDelete: () => onDeleteBook(context, books[index]),
            );
          },
        );
      },
    );
  }

  int _calculateColumns(double width) {
    if (width >= 1500) return 6;      // Extra large screens
    if (width >= 1200) return 5;      // Large desktop
    if (width >= 900) return 4;       // Medium desktop
    if (width >= 700) return 3;       // Small desktop
    return 2;                         // Minimum columns
  }

  double _calculateAspectRatio(double width) {
    if (width >= 1500) return 0.75;    // Extra large screens
    if (width >= 1200) return 0.72;    // Large desktop
    if (width >= 900) return 0.7;      // Medium desktop
    if (width >= 700) return 0.68;     // Small desktop
    return 0.65;                       // Minimum width
  }

  double _calculatePadding(double width) {
    if (width >= 1500) return 48;      // Extra large screens
    if (width >= 1200) return 40;      // Large desktop
    if (width >= 900) return 32;       // Medium desktop
    if (width >= 700) return 24;       // Small desktop
    return 16;                         // Minimum width
  }
}