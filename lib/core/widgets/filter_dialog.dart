import 'package:flutter/material.dart';
import '../services/firestore/genres_firestore_service.dart';
import '../../features/books/models/genre.dart';

class FilterDialog extends StatefulWidget {
  const FilterDialog({super.key});

  @override
  State<FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  final Set<String> _selectedGenres = {};
  final Set<String> _selectedAvailability = {};
  final Set<String> _selectedLanguages = {};
  final _genresService = GenresFirestoreService();
  
  final List<String> _availabilityOptions = [
    'Available',
    'Not Available',
  ];

  final List<String> _languages = [
    'Chinese',
    'English',
    'French',
    'German',
    'Spanish',
  ];
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    
    return Container(
      constraints: BoxConstraints(
        maxHeight: mediaQuery.size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filter Books',
                        style: theme.textTheme.titleLarge,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),
                  
                  // Genre Filter Section
                  const Text(
                    'Genre',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder<List<Genre>>(
                    stream: _genresService.getGenresStream(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      }
                      
                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      final genres = snapshot.data!;
                      // Sort genres alphabetically by name
                      genres.sort((a, b) => a.name.compareTo(b.name));

                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: genres.map((genre) => FilterChip(
                          label: Text(genre.name),
                          selected: _selectedGenres.contains(genre.id),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedGenres.add(genre.id);
                              } else {
                                _selectedGenres.remove(genre.id);
                              }
                            });
                          },
                        )).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Availability Filter Section
                  const Text(
                    'Availability',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availabilityOptions.map((status) => FilterChip(
                      label: Text(status),
                      selected: _selectedAvailability.contains(status),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedAvailability.add(status);
                          } else {
                            _selectedAvailability.remove(status);
                          }
                        });
                      },
                    )).toList(),
                  ),
                  const SizedBox(height: 16),
                  
                  // Language Filter Section
                  const Text(
                    'Language',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _languages.map((language) => FilterChip(
                      label: Text(language),
                      selected: _selectedLanguages.contains(language),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedLanguages.add(language);
                          } else {
                            _selectedLanguages.remove(language);
                          }
                        });
                      },
                    )).toList(),
                  ),
                  const SizedBox(height: 24),
                  
                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedGenres.clear();
                            _selectedAvailability.clear();
                            _selectedLanguages.clear();
                          });
                        },
                        child: const Text('Clear All'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () {
                          Navigator.pop(context, {
                            'genres': _selectedGenres.toList(),
                            'availability': _selectedAvailability.toList(),
                            'languages': _selectedLanguages.toList(),
                          });
                        },
                        child: const Text('Apply'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 