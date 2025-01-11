import 'package:flutter/material.dart';
import '../models/genre.dart';
import '../../../core/services/firestore/genres_firestore_service.dart';

class GenreManagementDialog extends StatefulWidget {
  final List<String> initialSelected;

  const GenreManagementDialog({
    this.initialSelected = const [],
    super.key,
  });

  @override
  State<GenreManagementDialog> createState() => _GenreManagementDialogState();
}

class _GenreManagementDialogState extends State<GenreManagementDialog> {
  final _genresService = GenresFirestoreService();
  final Set<String> _selectedGenres = {};
  final _newGenreController = TextEditingController();
  final _searchController = TextEditingController();
  bool _isAddingGenre = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedGenres.addAll(widget.initialSelected);
  }

  @override
  void dispose() {
    _newGenreController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Genre> _filterGenres(List<Genre> genres) {
    if (_searchQuery.isEmpty) return genres;
    return genres.where((genre) => 
      genre.name.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 600;
    final dialogWidth = isDesktop ? 600.0 : MediaQuery.of(context).size.width * 0.9;
    final dialogHeight = isDesktop ? 700.0 : MediaQuery.of(context).size.height * 0.8;
    
    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: dialogHeight,
        ),
        child: Padding(
          padding: EdgeInsets.all(isDesktop ? 24 : 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with Title and Close button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Manage Genres',
                    style: theme.textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Add Search TextField
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search genres...',
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
              const SizedBox(height: 16),
              
              // Add New Genre Section
              if (!_isAddingGenre)
                FilledButton.icon(
                  onPressed: () => setState(() => _isAddingGenre = true),
                  icon: const Icon(Icons.add),
                  label: Text(isDesktop ? 'Add New Genre' : 'Add'),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _newGenreController,
                        decoration: InputDecoration(
                          labelText: 'New Genre Name',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.check_circle),
                            onPressed: _addGenre,
                          ),
                        ),
                        onSubmitted: (_) => _addGenre(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() {
                        _isAddingGenre = false;
                        _newGenreController.clear();
                      }),
                    ),
                  ],
                ),
              const SizedBox(height: 16),
              
              // Genre List
              Expanded(
                child: StreamBuilder<List<Genre>>(
                  stream: _genresService.getGenresStream(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final genres = _filterGenres(snapshot.data ?? []);
                    
                    if (genres.isEmpty && _searchQuery.isNotEmpty) {
                      return Center(
                        child: Text(
                          'No genres found matching "$_searchQuery"',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurface.withAlpha(100),
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: genres.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final genre = genres[index];
                        return CheckboxListTile(
                          value: _selectedGenres.contains(genre.id),
                          onChanged: (value) {
                            setState(() {
                              if (value ?? false) {
                                _selectedGenres.add(genre.id);
                              } else {
                                _selectedGenres.remove(genre.id);
                              }
                            });
                          },
                          title: Text(genre.name),
                          secondary: genre.isDefault
                              ? Chip(
                                  label: const Text('Default'),
                                  labelStyle: TextStyle(
                                    fontSize: isDesktop ? 12 : 10,
                                  ),
                                )
                              : IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  color: theme.colorScheme.error,
                                  onPressed: () => _removeGenre(genre),
                                ),
                        );
                      },
                    );
                  },
                ),
              ),
              
              // Bottom Actions
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(null),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(_selectedGenres.toList()),
                      child: const Text('Done'),
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

  Future<void> _addGenre() async {
    if (_newGenreController.text.isEmpty) return;
    
    try {
      await _genresService.addGenre(_newGenreController.text.trim());
      if (mounted) {
        setState(() {
          _isAddingGenre = false;
          _newGenreController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _removeGenre(Genre genre) async {
    if (!mounted) return;
    final theme = Theme.of(context);
    
    if (genre.isDefault) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot remove default genres')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Genre'),
        content: Text('Are you sure you want to remove "${genre.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _genresService.removeGenre(genre.id);
        if (mounted) {
          setState(() => _selectedGenres.remove(genre.id));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }
} 