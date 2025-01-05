import 'package:flutter/material.dart';
import '../../models/book.dart';
import '../../../../core/theme/app_theme.dart';

class BookInfoRow extends StatelessWidget {
  final Book book;

  const BookInfoRow({
    super.key,
    required this.book,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? AppTheme.dark : AppTheme.light;
    
    return RepaintBoundary(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: _InfoBox(
                    label: 'Rating',
                    value: '${book.averageRating.toStringAsFixed(1)}/5',
                    icon: const Icon(Icons.star, color: Colors.amber, size: 28),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _InfoBox(
                    label: 'Pages',
                    value: '${book.pageCount}',
                    icon: const Icon(Icons.menu_book, color: Colors.blue, size: 28),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _InfoBox(
                    label: 'Language',
                    value: book.language.toUpperCase(),
                    icon: const Icon(Icons.language, color: Colors.green, size: 28),
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _IsbnBox(isbn: book.isbn ?? 'N/A', isDark: isDark),
            const SizedBox(height: 16),
            _CategoriesBox(categories: book.categories, isDark: isDark),
          ],
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String label;
  final String value;
  final Widget icon;
  final bool isDark;

  const _InfoBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final colors = isDark ? AppTheme.dark : AppTheme.light;
    
    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: colors.surface.withAlpha(150),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colors.primary.withAlpha(isDark ? 100 : 300),
            width: 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colors.textSubtle,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colors.onBackground,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _IsbnBox extends StatelessWidget {
  final String isbn;
  final bool isDark;

  const _IsbnBox({
    required this.isbn,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: isDark 
            ? AppTheme.dark.surface.withAlpha(179)
            : AppTheme.light.surface.withAlpha(179),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark 
              ? AppTheme.dark.primary.withAlpha(128)
              : AppTheme.light.primary.withAlpha(230),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.qr_code, color: Colors.purple, size: 28),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ISBN',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isbn,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoriesBox extends StatelessWidget {
  final List<String> categories;
  final bool isDark;

  const _CategoriesBox({
    required this.categories,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final colors = isDark ? AppTheme.dark : AppTheme.light;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: colors.surface.withAlpha(150),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark 
              ? colors.primary.withAlpha(100)
              : colors.primary.withAlpha(300),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(100),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.category, color: Colors.purple, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Categories',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: colors.textSubtle,
                  ),
                ),
                const SizedBox(height: 8),
                if (categories.isEmpty)
                  Text(
                    'N/A',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colors.onBackground,
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categories.map((category) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: colors.primary.withOpacity(0.5),
                        ),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: colors.onBackground,
                        ),
                      ),
                    )).toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}