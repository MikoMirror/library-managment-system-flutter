import 'package:cloud_firestore/cloud_firestore.dart';

class Book {
  final String? id;
  final String? isbn;
  final String title;
  final String author;
  final String description;
  final String categories;
  final int pageCount;
  final Timestamp? publishedDate;
  final String? externalImageUrl;
  final int booksQuantity;
  final int averageScore;

  Book({
    this.id,
    this.isbn,
    required this.title,
    required this.author,
    required this.description,
    required this.categories,
    required this.pageCount,
    this.publishedDate,
    this.externalImageUrl,
    this.booksQuantity = 0,
    this.averageScore = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'isbn': isbn,
      'title': title,
      'author': author,
      'description': description,
      'categories': categories,
      'pageCount': pageCount,
      'publishedDate': publishedDate,
      'externalImageUrl': externalImageUrl,
      'booksQuantity': booksQuantity,
      'averageScore': averageScore,
    };
  }

  factory Book.fromMap(Map<String, dynamic> map, String documentId) {
    return Book(
      id: documentId,
      isbn: map['isbn'],
      title: map['title'],
      author: map['author'],
      description: map['description'],
      categories: map['categories'],
      pageCount: map['pageCount'],
      publishedDate: map['publishedDate'],
      externalImageUrl: map['externalImageUrl'],
      booksQuantity: map['booksQuantity'] ?? 0,
      averageScore: map['averageScore'] ?? 0,
    );
  }
} 