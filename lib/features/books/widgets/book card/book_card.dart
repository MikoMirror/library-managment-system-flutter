import 'package:flutter/material.dart';
import '../../models/book.dart';
import '../../../../core/services/image/image_cache_service.dart';
import '../../screens/book_details_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/book_card_bloc.dart';
import '../../repositories/books_repository.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../delete_book_dialog.dart';
import 'package:cached_network_image/cached_network_image.dart';


class BookCard extends StatefulWidget {
  final Book book;
  final bool isMobile;
  final bool isAdmin;
  final String? userId;
  final VoidCallback? onDelete;
  final bool showAdminControls;
  final bool compact;

  const BookCard({
    super.key,
    required this.book,
    this.isMobile = false,
    this.isAdmin = false,
    this.userId,
    this.onDelete,
    this.showAdminControls = true,
    this.compact = false,
  });

  @override
  State<BookCard> createState() => _BookCardState();
}

class _BookCardState extends State<BookCard> {
  BookCardBloc? _bookCardBloc;

  @override
  void initState() {
    super.initState();
    _initializeBloc();
  }

  void _initializeBloc() {
    // Initialize bloc only for non-admin users when controls should be shown
    if (!widget.isAdmin && 
        widget.showAdminControls && 
        widget.userId != null) {
      _bookCardBloc = BookCardBloc(context.read<BooksRepository>())
        ..add(LoadFavoriteStatus(widget.userId!, widget.book.id!));
    }
  }

  @override
  void dispose() {
    _bookCardBloc?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BookDetailsScreen(bookId: widget.book.id),
            ),
          );
        },
        child: widget.isMobile ? _buildMobileCard() : _buildDesktopCard(),
      ),
    );
  }

  Widget _buildActionButton() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget icon;
    VoidCallback? onPressed;

    // Early return for admin with delete button
    if (widget.isAdmin) {
      icon = const Icon(Icons.delete, color: Colors.red, size: 20);
      onPressed = () {
        showDialog(
          context: context,
          builder: (context) => DeleteBookDialog(book: widget.book),
        );
      };
    } 
    // Only initialize favorite functionality for non-admin users
    else if (!widget.isAdmin && widget.showAdminControls && widget.userId != null) {
      return BlocBuilder<BookCardBloc, BookCardState>(
        bloc: _bookCardBloc,
        builder: (context, state) {
          if (state is FavoriteStatusLoading) {
            return Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            );
          }

          final isFavorite = state is FavoriteStatusLoaded ? state.isFavorite : false;
          
          return Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: widget.isMobile ? Colors.transparent : Colors.black54,
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              onTap: () {
                if (widget.userId != null) {
                  _bookCardBloc?.add(ToggleFavorite(widget.userId!, widget.book.id!));
                }
              },
              child: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: Colors.red,
                size: 20,
              ),
            ),
          );
        },
      );
    } 
    else {
      return const SizedBox.shrink();
    }

    // For admin delete button
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: widget.isMobile ? Colors.transparent : Colors.black54,
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onPressed,
        child: icon,
      ),
    );
  }

  Widget _buildDesktopCard() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final coreColors = isDark ? AppTheme.dark : AppTheme.light;
    
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: widget.compact ? 2 : 4,
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: 0.7,
            child: CachedNetworkImage(
              imageUrl: widget.book.coverUrl,
              placeholder: (context, url) => Container(
                color: Colors.grey[300],
              ),
              fadeInDuration: const Duration(milliseconds: 300),
              fit: BoxFit.cover,
            ),
          ),

          Positioned(
            top: 8,
            left: 8,
            child: _buildRatingIndicator(),
          ),

          Positioned(
            top: 8,
            right: 8,
            child: _buildActionButton(),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                child: Container(
                  color: Colors.black.withOpacity(0.7),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 48,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                widget.book.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              widget.book.author,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

   Widget _buildMobileCard() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: Stack(
        children: [
          Row(
            children: [
              SizedBox(
                width: 90,
                height: 130,
                child: ImageCacheService().buildCachedImage(
                  imageUrl: widget.book.coverUrl,
                  fit: BoxFit.cover,
                ),
              ),
              const Spacer(),
            ],
          ),

          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  stops: const [0.0, 0.3, 1.0],
                  colors: [
                    Colors.transparent,
                    (isDark ? AppTheme.dark.primary : AppTheme.light.primary).withOpacity(0.1),
                    (isDark ? AppTheme.dark.primary : AppTheme.light.primary).withOpacity(0.3),
                  ],
                ),
              ),
            ),
          ),

          Row(
            children: [
              const SizedBox(width: 90),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              widget.book.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              widget.book.author,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildRatingIndicator(isMobile: true),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: _buildActionButton(),
              ),
            ],
          ),
        ],
      ),
    );
  }
  

  TextStyle mobileAuthorStyle(BuildContext context) {
    return TextStyle(
      fontSize: 14,
      color: Colors.grey[600],
    );
  }

  Widget _buildRatingIndicator({bool isMobile = false}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isMobile 
            ? Colors.transparent
            : Colors.black54,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.star,
            size: 16,
            color: Colors.amber,
          ),
          const SizedBox(width: 4),
          Text(
            widget.book.averageRating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isMobile
                  ? (isDark ? Colors.white70 : Colors.black54)
                  : Colors.white,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '(${widget.book.ratingsCount})',
            style: TextStyle(
              fontSize: 12,
              color: isMobile
                  ? (isDark ? Colors.white60 : Colors.black45)
                  : Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}
