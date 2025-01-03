import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/api/open_library_service.dart';

class Book {
  final String? id;
  final String title;
  final String author;
  final String isbn;
  final String description;
  final List<String> categories;
  final int pageCount;
  final String? externalImageUrl;
  final Timestamp? publishedDate;
  final int booksQuantity;
  final String language;
  final Map<String, double> ratings;

  Book({
    this.id,
    required this.title,
    required this.author,
    required this.isbn,
    required this.description,
    required this.categories,
    required this.pageCount,
    this.externalImageUrl,
    this.publishedDate,
    this.booksQuantity = 0,
    this.language = 'en',
    this.ratings = const {},
  });

  double get averageRating {
    if (ratings.isEmpty) return 0;
    return ratings.values.reduce((a, b) => a + b) / ratings.length;
  }

  int get ratingsCount => ratings.length;

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'author': author,
      'isbn': isbn,
      'description': description,
      'categories': categories,
      'pageCount': pageCount,
      'externalImageUrl': externalImageUrl,
      'publishedDate': publishedDate,
      'booksQuantity': booksQuantity,
      'language': language,
      'ratings': ratings,
    };
  }

  factory Book.fromMap(Map<String, dynamic> map, [String? id]) {
    return Book(
      id: id,
      title: map['title'] ?? '',
      author: map['author'] ?? '',
      isbn: map['isbn'] ?? '',
      description: map['description'] ?? '',
      categories: List<String>.from(map['categories'] ?? []),
      pageCount: map['pageCount'] ?? 0,
      externalImageUrl: map['externalImageUrl'],
      publishedDate: map['publishedDate'],
      booksQuantity: map['booksQuantity'] ?? 0,
      language: map['language'] ?? 'en',
      ratings: Map<String, double>.from(map['ratings'] ?? {}),
    );
  }

  Book copyWith({
    String? id,
    String? title,
    String? author,
    String? isbn,
    String? description,
    List<String>? categories,
    int? pageCount,
    String? externalImageUrl,
    Timestamp? publishedDate,
    int? booksQuantity,
    String? language,
    Map<String, double>? ratings,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      isbn: isbn ?? this.isbn,
      description: description ?? this.description,
      categories: categories ?? this.categories,
      pageCount: pageCount ?? this.pageCount,
      externalImageUrl: externalImageUrl ?? this.externalImageUrl,
      publishedDate: publishedDate ?? this.publishedDate,
      booksQuantity: booksQuantity ?? this.booksQuantity,
      language: language ?? this.language,
      ratings: ratings ?? this.ratings,
    );
  }

  String get coverUrl {
    if (externalImageUrl == null) return 'placeholder_url';
    
    if (externalImageUrl!.contains('books.google.com')) {
      final uri = Uri.parse(externalImageUrl!);
      final params = Map<String, String>.from(uri.queryParameters);
      
      params['zoom'] = '4';
      params['edge'] = 'curl';
      params['img'] = '1';
      
      return Uri(
        scheme: uri.scheme,
        host: uri.host,
        path: uri.path,
        queryParameters: params,
      ).toString();
    }
    
    if (OpenLibraryService.isOpenLibraryUrl(externalImageUrl!)) {
      return OpenLibraryService.transformCoverUrl(externalImageUrl!, isLarge: true);
    }
    
    return externalImageUrl!;
  }
} 