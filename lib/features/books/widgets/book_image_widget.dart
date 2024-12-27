import 'package:flutter/material.dart';
import '../models/book.dart';
import 'package:cached_network_image/cached_network_image.dart';


class BookImageWidget extends StatelessWidget {
  final Book book;
  final bool isDetailView;
  final double? maxHeight;
  final VoidCallback? onTap;
  final bool isAdmin;
  final String userId;
  final Function(bool)? onFavoriteToggle;

  const BookImageWidget({
    super.key,
    required this.book,
    this.isDetailView = false,
    this.maxHeight,
    this.onTap,
    required this.isAdmin,
    required this.userId,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    final imageWidget = book.externalImageUrl != null
        ? CachedNetworkImage(
            imageUrl: book.externalImageUrl!,
            fit: BoxFit.cover,
            placeholder: (context, url) => const Center(
              child: CircularProgressIndicator(),
            ),
            errorWidget: (context, url, error) => const Icon(Icons.error),
          )
        : Image.asset(
            'assets/images/book_placeholder.png',
            fit: BoxFit.cover,
          );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: maxHeight != null
            ? BoxConstraints(maxHeight: maxHeight!)
            : null,
        child: AspectRatio(
          aspectRatio: isDetailView ? 3 / 4 : 2 / 3,
          child: Stack(
            children: [
              imageWidget,
              if (onFavoriteToggle != null)
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: const Icon(Icons.favorite_border),
                    onPressed: () => onFavoriteToggle!(true),
                    color: Colors.white,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
} 