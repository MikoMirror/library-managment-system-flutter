import 'package:flutter/material.dart';
import 'dart:async';
import '../../models/book.dart';
import 'book_card.dart';
import '../../screens/book_info_screen.dart';
import '../../../../core/services/database/firestore_service.dart';
import 'book_card_mixin.dart';
import '../../../../features/users/models/user_model.dart';

class DesktopBooksGrid extends StatefulWidget {
  final List<Book> books;
  final dynamic user;  // This will be either UserModel or Firebase User
  final Function(BuildContext, Book) onDeleteBook;

  static const double minGridPadding = 24.0;
  static const double minGridSpacing = 24.0;
  static const double maxGridSpacing = 48.0;
  static const double maxWidth = 1400.0;

  const DesktopBooksGrid({
    super.key,
    required this.books,
    required this.user,
    required this.onDeleteBook,
  });

  @override
  State<DesktopBooksGrid> createState() => _DesktopBooksGridState();
}

class _DesktopBooksGridState extends State<DesktopBooksGrid> with BookCardMixin {
  Timer? _debounceTimer;
  Size? _lastSize;
  SliverGridDelegateWithFixedCrossAxisCount? _cachedGridDelegate;
  
  // Add stream controller to manage layout changes
  bool _isLayouting = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_cachedGridDelegate == null) {
      _cachedGridDelegate = _createGridDelegate(
        BoxConstraints(maxWidth: MediaQuery.of(context).size.width),
      );
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

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

  SliverGridDelegateWithFixedCrossAxisCount _calculateGridLayout(BoxConstraints constraints) {
    if (_isLayouting) return _cachedGridDelegate ?? _createGridDelegate(constraints);
    
    final currentSize = Size(constraints.maxWidth, constraints.maxHeight);
    if (_cachedGridDelegate != null && _lastSize == currentSize) {
      return _cachedGridDelegate!;
    }

    _isLayouting = true;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 150), () {
      if (mounted) {
        _isLayouting = false;
        _cachedGridDelegate = _createGridDelegate(constraints);
        handleLayoutChange();
      }
    });

    return _cachedGridDelegate ?? _createGridDelegate(constraints);
  }

  SliverGridDelegateWithFixedCrossAxisCount _createGridDelegate(BoxConstraints constraints) {
    final availableWidth = constraints.maxWidth - (DesktopBooksGrid.minGridPadding * 2);
    final columnCount = (availableWidth / BookCard.desktopCardWidth).floor();
    final columns = columnCount.clamp(2, 6);

    final remainingSpace = availableWidth - (BookCard.desktopCardWidth * columns);
    final dynamicSpacing = (remainingSpace / (columns - 1))
        .clamp(DesktopBooksGrid.minGridSpacing, DesktopBooksGrid.maxGridSpacing);

    _lastSize = Size(constraints.maxWidth, constraints.maxHeight);
    
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: columns,
      childAspectRatio: BookCard.desktopCardWidth / BookCard.desktopCardHeight,
      crossAxisSpacing: dynamicSpacing,
      mainAxisSpacing: dynamicSpacing,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gridLayout = _calculateGridLayout(constraints);
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(DesktopBooksGrid.minGridPadding),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: DesktopBooksGrid.maxWidth),
              child: GridView.builder(
                key: ValueKey('desktop-grid-${_lastSize?.width ?? 0}'),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: gridLayout,
                itemCount: widget.books.length,
                itemBuilder: (context, index) {
                  final book = widget.books[index];
                  return KeyedSubtree(
                    key: ValueKey('book-${book.id}'),
                    child: RepaintBoundary(
                      child: buildBookCard(
                        book: book,
                        isMobile: false,
                        isAdmin: isAdmin,
                        userId: userId ?? '',
                        onDeleteBook: widget.onDeleteBook,
                        context: context,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
} 