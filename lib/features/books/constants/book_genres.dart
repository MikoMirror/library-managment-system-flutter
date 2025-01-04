class Genre {
  final String id;
  final String name;
  
  const Genre({required this.id, required this.name});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Genre &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class BookGenres {
  static const List<Genre>  _allGenres = [
    Genre(id: 'action', name: 'Action'),
    Genre(id: 'adventure', name: 'Adventure'),
    Genre(id: 'biography', name: 'Biography'),
    Genre(id: 'children', name: 'Children'),
    Genre(id: 'comedy', name: 'Comedy'),
    Genre(id: 'crime', name: 'Crime'),
    Genre(id: 'drama', name: 'Drama'),
    Genre(id: 'fantasy', name: 'Fantasy'),
    Genre(id: 'historical_fiction', name: 'Historical Fiction'),
    Genre(id: 'horror', name: 'Horror'),
    Genre(id: 'mystery', name: 'Mystery'),
    Genre(id: 'non_fiction', name: 'Non-fiction'),
    Genre(id: 'romance', name: 'Romance'),
    Genre(id: 'science_fiction', name: 'Science Fiction'),
    Genre(id: 'thriller', name: 'Thriller'),
    Genre(id: 'autobiography', name: 'Autobiography'),
    Genre(id: 'classic', name: 'Classic'),
    Genre(id: 'cooking', name: 'Cooking'),
    Genre(id: 'dystopian', name: 'Dystopian'),
    Genre(id: 'education', name: 'Education'),
    Genre(id: 'family', name: 'Family'),
    Genre(id: 'graphic_novel', name: 'Graphic Novel'),
    Genre(id: 'health_wellness', name: 'Health & Wellness'),
    Genre(id: 'memoir', name: 'Memoir'),
    Genre(id: 'philosophy', name: 'Philosophy'),
    Genre(id: 'poetry', name: 'Poetry'),
    Genre(id: 'political', name: 'Political'),
    Genre(id: 'religious', name: 'Religious'),
    Genre(id: 'self_help', name: 'Self-help'),
    Genre(id: 'short_stories', name: 'Short Stories'),
    Genre(id: 'sports', name: 'Sports'),
    Genre(id: 'supernatural', name: 'Supernatural'),
    Genre(id: 'travel', name: 'Travel'),
    Genre(id: 'young_adult', name: 'Young Adult'),
  ];

  static List<Genre> getAllGenres() {
    final genres = List<Genre>.from(_allGenres);
    genres.sort((a, b) => a.name.compareTo(b.name));
    return genres;
  }

  static void addGenre(Genre genre) {
    if (!_allGenres.contains(genre)) {
      _allGenres.add(genre);
    }
  }

  static void removeGenre(Genre genre) {
    _allGenres.remove(genre);
  }

  static bool isValidGenre(String id) {
    return _allGenres.any((genre) => genre.id == id);
  }
}
