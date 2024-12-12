import 'package:flutter/material.dart';
import '../../models/book.dart';
import 'book_card_styles.dart';
import '../../../../core/services/image/image_cache_service.dart';
import '../../screens/book_details_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/book_card_bloc.dart';
import '../../repositories/books_repository.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';


class BookCard extends StatefulWidget {
  final Book book;
  final bool isMobile;
  final bool isAdmin;
  final String? userId;
  final VoidCallback? onDelete;

  const BookCard({
    super.key,
    required this.book,
    this.isMobile = false,
    this.isAdmin = false,
    this.userId,
    this.onDelete,
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
    if (!widget.isAdmin && widget.userId != null) {
      _bookCardBloc.add(LoadFavoriteStatus(widget.userId!, widget.book.id!));
    }
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
      child: widget.isMobile ? _buildMobileCard() : _buildDesktopCard(),
    );
  }

  Widget _buildActionButton() {
    if (widget.isAdmin) {
      return IconButton(
        icon: const Icon(Icons.delete, color: Colors.red),
        onPressed: widget.onDelete,
      );
    } else {
      return BlocBuilder<BookCardBloc, BookCardState>(
        bloc: _bookCardBloc,
        builder: (context, state) {
          bool isFavorite = false;
          if (state is FavoriteStatusLoaded) {
            isFavorite = state.isFavorite;
          }

          return IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: Colors.red,
            ),
            onPressed: () {
              if (widget.userId != null) {
                _bookCardBloc.add(ToggleFavorite(widget.userId!, widget.book.id!));
              }
            },
          );
        },
      );
    }
  }

  Widget _buildDesktopCard() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      child: Stack(
        children: [
          ImageCacheService().buildCachedImage(
            imageUrl: widget.book.coverUrl,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),

          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.5, 0.7, 1.0],
                  colors: isDark ? [
                    Colors.transparent,
                    AppTheme.darkGradient1.withOpacity(0.7),
                    AppTheme.darkGradient3.withOpacity(0.95),
                  ] : [
                    Colors.transparent,
                    AppTheme.primaryLight.withOpacity(0.3),
                    AppTheme.primaryLight.withOpacity(0.9),
                  ],
                ),
              ),
            ),
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
                filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.4, 1.0],
                      colors: isDark ? [
                        AppTheme.darkGradient1.withOpacity(0.3),
                        AppTheme.darkGradient2.withOpacity(0.7),
                        AppTheme.darkGradient3.withOpacity(0.95),
                      ] : [
                        AppTheme.primaryLight.withOpacity(0.1),
                        AppTheme.primaryLight.withOpacity(0.6),
                        AppTheme.primaryLight.withOpacity(0.9),
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 48,
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
                      const SizedBox(height: 4),
                      Text(
                        widget.book.author,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                height: 120,
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
                    (isDark ? AppTheme.primaryDark : AppTheme.primaryLight).withOpacity(0.3),
                    (isDark ? AppTheme.primaryDark : AppTheme.primaryLight).withOpacity(0.9),
                  ],
                ),
              ),
            ),
          ),

          Row(
            children: [
              const SizedBox(width: 90), // Space for image
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 48,
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
                      const SizedBox(height: 4),
                      Text(
                        widget.book.author,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
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
}
