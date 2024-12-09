import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/book.dart';
import 'book_card_styles.dart';
import '../../../../core/services/image/image_cache_service.dart';
import '../../screens/book_details_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/book_card_bloc.dart';
import '../../repositories/books_repository.dart';


class BookCard extends StatefulWidget {
  final Book book;
  final bool isMobile;
  final bool isAdmin;
  final String? userId;
  final Function(bool)? onFavoriteToggle;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;
  final bool initialFavoriteStatus;

  // Fixed dimensions for desktop cards
  static const double desktopCardWidth = 260.0;
  static const double desktopCardHeight = 400.0;
  // Mobile card dimensions
  static const double mobileCardHeight = 120.0;
  static const double mobileImageWidth = 90.0;
  // Define the card border radius
  static const double _cardBorderRadius = 12.0;

  const BookCard({
    super.key,
    required this.book,
    this.isMobile = false,
    this.isAdmin = false,
    this.userId,
    this.onFavoriteToggle,
    this.onDelete,
    this.onTap,
    this.initialFavoriteStatus = false,
  });

  @override
  State<BookCard> createState() => _BookCardState();
}

class _BookCardState extends State<BookCard> {
  late BookCardBloc _bookCardBloc;

  @override
  void initState() {
    super.initState();
    _bookCardBloc = BookCardBloc(context.read<BooksRepository>());
    _bookCardBloc.add(LoadFavoriteStatus(widget.userId!, widget.book.id!));
  }

  @override
  void dispose() {
    _bookCardBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookDetailsScreen(bookId: widget.book.id),
          ),
        );
      },
      child: widget.isMobile ? _buildMobileCard(context) : _buildDesktopCard(context),
    );
  }

  Widget _buildDesktopCard(BuildContext context) {
    return BlocBuilder<BookCardBloc, BookCardState>(
      bloc: _bookCardBloc,
      builder: (context, state) {
        bool isFavorite = false;
        if (state is FavoriteStatusLoaded) {
          isFavorite = state.isFavorite;
        }

        return Card(
          clipBehavior: Clip.antiAlias,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BookCard._cardBorderRadius),
          ),
          child: InkWell(
            splashColor: Colors.white30,
            highlightColor: Colors.white10,
            child: Stack(
              children: [
                _buildBackgroundImage(),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _buildFrostedGlassOverlay(
                    child: _buildDesktopText(),
                  ),
                ),
                if (!widget.isAdmin)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: Colors.red,
                      ),
                      onPressed: () {
                        _bookCardBloc.add(ToggleFavorite(widget.userId!, widget.book.id!));
                        widget.onFavoriteToggle?.call(isFavorite);
                      },
                    ),
                  ),
                if (widget.isAdmin && widget.onDelete != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: widget.onDelete,
                      color: Colors.grey[800],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMobileCard(BuildContext context) {
    return BlocBuilder<BookCardBloc, BookCardState>(
      bloc: _bookCardBloc,
      builder: (context, state) {
        bool isFavorite = false;
        if (state is FavoriteStatusLoaded) {
          isFavorite = state.isFavorite;
        }

        return Card(
          clipBehavior: Clip.antiAlias,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BookCard._cardBorderRadius),
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BookDetailsScreen(bookId: widget.book.id),
                ),
              );
            },
            child: SizedBox(
              height: BookCard.mobileCardHeight,
              child: Row(
                children: [
                  // Book cover image
                  Hero(
                    tag: 'book-${widget.book.id}',
                    child: SizedBox(
                      width: BookCard.mobileImageWidth,
                      height: double.infinity,
                      child: ImageCacheService().buildCachedImage(
                        imageUrl: widget.book.externalImageUrl ?? 'placeholder_url',
                        width: BookCard.mobileImageWidth,
                        height: BookCard.mobileCardHeight,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  // Book details
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title and author
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  widget.book.title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.book.author,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          // Actions (favorite/delete)
                          if (!widget.isAdmin) ...[
                            IconButton(
                              icon: Icon(
                                isFavorite ? Icons.favorite : Icons.favorite_border,
                                color: Colors.red,
                              ),
                              onPressed: () {
                                _bookCardBloc.add(
                                  ToggleFavorite(widget.userId!, widget.book.id!),
                                );
                                widget.onFavoriteToggle?.call(isFavorite);
                              },
                            ),
                          ],
                          if (widget.isAdmin && widget.onDelete != null) ...[
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: widget.onDelete,
                              color: Colors.grey[800],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBackgroundImage() {
    return Positioned.fill(
      child: ImageCacheService().buildCachedImage(
        imageUrl: widget.book.externalImageUrl ?? 'placeholder_url',
        width: BookCard.desktopCardWidth,
        height: BookCard.desktopCardHeight,
      ),
    );
  }

  Widget _buildDesktopText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.book.title,
          style: BookCardStyles.desktopTitleStyle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          widget.book.author,
          style: BookCardStyles.desktopAuthorStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildMobileImage() {
    return SizedBox(
      width: BookCard.mobileImageWidth,
      height: double.infinity,
      child: ImageCacheService().buildCachedImage(
        imageUrl: widget.book.externalImageUrl ?? 'placeholder_url',
        width: BookCard.mobileImageWidth,
        height: BookCard.mobileCardHeight,
      ),
    );
  }

  Widget _buildMobileText(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.book.title,
              style: BookCardStyles.mobileTitleStyle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              widget.book.author,
              style: BookCardStyles.mobileAuthorStyle(context),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFrostedGlassOverlay({required Widget child}) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(BookCard._cardBorderRadius)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          color: Colors.black.withOpacity(0.6),
          child: child,
        ),
      ),
    );
  }
}
