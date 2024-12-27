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
    
    // Defer Firestore operations to after frame
    if (!widget.isAdmin && widget.userId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _bookCardBloc.add(LoadFavoriteStatus(widget.userId!, widget.book.id!));
        }
      });
    }
  }

  @override
  void dispose() {
    _bookCardBloc.close();
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
    if (widget.isAdmin) {
      return IconButton(
        icon: const Icon(Icons.delete, color: Colors.red),
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => DeleteBookDialog(book: widget.book),
          );
        },
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
    final coreColors = isDark ? AppTheme.dark : AppTheme.light;
    
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
                      const SizedBox(height: 4),
                      Text(
                        widget.book.author,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
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
                      (isDark ? AppTheme.dark.primary : AppTheme.light.primary).withOpacity(0.1),
                      (isDark ? AppTheme.dark.primary : AppTheme.light.primary).withOpacity(0.3),
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
