import 'package:flutter/material.dart';
import '../models/book.dart';
import '../services/firestore_service.dart';

class BookCard extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final bool isAdmin;
  final String userId;
  final VoidCallback onFavoriteToggle;

  const BookCard({
    super.key,
    required this.book,
    required this.onTap,
    this.onDelete,
    required this.isAdmin,
    required this.userId,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 180,
          padding: const EdgeInsets.all(8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Book Cover Image
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  width: 120,
                  height: 180,
                  child: book.externalImageUrl != null
                      ? Image.network(
                          book.externalImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildPlaceholder();
                          },
                        )
                      : _buildPlaceholder(),
                ),
              ),
              const SizedBox(width: 8),
              // Book Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                book.title,
                                style: theme.textTheme.titleMedium,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: isAdmin 
                            ? IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: onDelete,
                              )
                            : StreamBuilder<bool>(
                                stream: FirestoreService().isBookFavorited(userId, book.id!),
                                builder: (context, snapshot) {
                                  final isFavorited = snapshot.data ?? false;
                                  return IconButton(
                                    icon: Icon(
                                      isFavorited ? Icons.favorite : Icons.favorite_border,
                                      color: isFavorited ? Colors.red : null,
                                    ),
                                    onPressed: onFavoriteToggle,
                                  );
                                },
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book.author,
                      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14.0),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pages: ${book.pageCount > 0 ? book.pageCount : 'Unknown'}',
                      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12.0),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Text(
                        book.description,
                        style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12.0),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(Icons.book, size: 40, color: Colors.grey),
      ),
    );
  }
} 
