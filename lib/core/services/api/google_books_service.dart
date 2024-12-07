// ignore_for_file: avoid_print
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../features/books/models/book.dart';

class GoogleBooksService {
  static const String _baseUrl = 'https://www.googleapis.com/books/v1/volumes';
  static const String _apiKey = 'AIzaSyDYdzcHQvTCSLxmFpEwH9Gpp6FQ_fJvloY'; 

  static Future<Book?> findBookByIsbn(String isbn) async {
    final response = await http.get(Uri.parse('https://www.googleapis.com/books/v1/volumes?q=isbn:$isbn'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['totalItems'] > 0) {
        final bookData = data['items'][0]['volumeInfo'];
        return Book(
          title: bookData['title'] ?? 'Unknown Title',
          author: bookData['authors']?.join(', ') ?? 'Unknown Author',
          isbn: isbn,
          description: bookData['description'] ?? 'No description available.',
          categories: bookData['categories']?.join(', ') ?? 'Uncategorized',
          pageCount: bookData['pageCount'] ?? 0,
          externalImageUrl: bookData['imageLinks']?['thumbnail'],
          publishedDate: bookData['publishedDate'] != null
              ? Timestamp.fromDate(DateTime.parse(bookData['publishedDate']))
              : null,
          language: bookData['language'] ?? 'en',
          ratings: {}, // Initialize with an empty map
        );
      }
    }
    return null;
  }
}