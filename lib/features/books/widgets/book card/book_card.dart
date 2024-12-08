import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/book.dart';
import 'book_card_styles.dart';
import '../../../../core/services/image/image_cache_service.dart';

class BookCard extends StatefulWidget {
  final Book book;
  final VoidCallback? onTap;
  final bool isMobile;
  final bool isAdmin;
  final String? userId;
  final Function(bool)? onFavoriteToggle;
  final VoidCallback? onDelete;
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
    this.onTap,
    this.isMobile = false,
    this.isAdmin = false,
    this.userId,
    this.onFavoriteToggle,
    this.onDelete,
    this.initialFavoriteStatus = false,
  });

  @override
  State<BookCard> createState() => _BookCardState();
}

class _BookCardState extends State<BookCard> {
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.initialFavoriteStatus;
  }

  @override
  void didUpdateWidget(BookCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialFavoriteStatus != widget.initialFavoriteStatus) {
      setState(() {
        _isFavorite = widget.initialFavoriteStatus;
      });
    }
  }

  Widget _buildDesktopCard(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BookCard._cardBorderRadius),
      ),
      child: InkWell(
        onTap: widget.onTap,
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
            if (widget.onFavoriteToggle != null || (widget.isAdmin && widget.onDelete != null))
              Positioned(
                top: 8,
                right: 8,
                child: _buildActionButtons(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileCard(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BookCard._cardBorderRadius),
      ),
      child: InkWell(
        onTap: widget.onTap,
        child: SizedBox(
          height: BookCard.mobileCardHeight,
          child: Row(
            children: [
              _buildMobileImage(),
              _buildMobileText(context),
              if (widget.onFavoriteToggle != null)
                IconButton(
                  icon: Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: Colors.red,
                  ),
                  onPressed: () {
                    setState(() {
                      _isFavorite = !_isFavorite;
                    });
                    widget.onFavoriteToggle!(_isFavorite);
                  },
                  color: Colors.red,
                ),
            ],
          ),
        ),
      ),
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

  Widget _buildFavoriteButton() {
    if (widget.onFavoriteToggle == null) return const SizedBox.shrink();
    
    return IconButton(
      icon: Icon(
        _isFavorite ? Icons.favorite : Icons.favorite_border,
        color: Colors.red,
      ),
      onPressed: () {
        setState(() {
          _isFavorite = !_isFavorite;
        });
        widget.onFavoriteToggle!(_isFavorite);
      },
      color: Colors.red,
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        _buildFavoriteButton(),
        if (widget.isAdmin && widget.onDelete != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: widget.onDelete,
              color: Colors.grey[800],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.isMobile ? _buildMobileCard(context) : _buildDesktopCard(context);
  }
}
