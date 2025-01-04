import 'package:flutter/material.dart';
import '../constants/book_genres.dart';
import '../../../core/theme/app_theme.dart';

class GenreManagementDialog extends StatefulWidget {
  const GenreManagementDialog({super.key});

  @override
  State<GenreManagementDialog> createState() => _GenreManagementDialogState();
}

class _GenreManagementDialogState extends State<GenreManagementDialog> {
  late List<Genre> _genres;
  final _nameController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _genres = BookGenres.getAllGenres();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addNewGenre() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Genre'),
        content: TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Genre Name',
            hintText: 'Enter genre name',
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (_nameController.text.isNotEmpty) {
                final genreName = _nameController.text.trim();
                final genreId = genreName.toLowerCase().replaceAll(' ', '_');
                
                final newGenre = Genre(id: genreId, name: genreName);
                BookGenres.addGenre(newGenre);
                
                setState(() {
                  _genres = BookGenres.getAllGenres();
                });
                
                _nameController.clear();
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _removeGenre(Genre genre) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Genre'),
        content: Text('Are you sure you want to remove "${genre.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              BookGenres.removeGenre(genre);
              setState(() {
                _genres = BookGenres.getAllGenres();
              });
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? AppTheme.dark : AppTheme.light;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 500,
          maxHeight: 600,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Manage Genres',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Available Genres',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  TextButton.icon(
                    onPressed: _addNewGenre,
                    icon: const Icon(Icons.add),
                    label: const Text('Add New'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Card(
                  child: ListView.builder(
                    itemCount: _genres.length,
                    itemBuilder: (context, index) {
                      final genre = _genres[index];
                      return ListTile(
                        title: Text(genre.name),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          color: colors.error,
                          onPressed: () => _removeGenre(genre),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 