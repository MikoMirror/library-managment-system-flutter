// ignore_for_file: avoid_print
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/book.dart';

class GoogleBooksService {
  static const String _baseUrl = 'https://www.googleapis.com/books/v1/volumes';
  static const String _apiKey = ''; 

  static Future<Book?> findBookByIsbn(String isbn) async {
    final service = GoogleBooksService();
    return service.getBookByISBN(isbn, _apiKey);
  }

  Future<Book?> getBookByISBN(String isbn, String apiKey) async {
    final url = '$_baseUrl?q=isbn:$isbn&key=$apiKey';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return _extractBookDataFromJson(response.body, isbn);
      } else {
        print('Google Books API request failed. Status Code: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching book data: $e');
      return null;
    }
  }

  Book? _extractBookDataFromJson(String jsonResponse, String isbn) {
    final Map<String, dynamic> jsonData = json.decode(jsonResponse);
    if (jsonData['totalItems'] > 0) {
      final volumeInfo = jsonData['items'][0]['volumeInfo'];
      String coverUrl = getOpenLibraryCoverUrl(isbn, 'L'); 
      return Book(
        title: volumeInfo['title'] ?? '',
        author: (volumeInfo['authors'] != null && volumeInfo['authors'].isNotEmpty)
            ? volumeInfo['authors'].join(', ')
            : '',
        isbn: isbn,
        description: volumeInfo['description'] ?? '',
        categories: (volumeInfo['categories'] != null && volumeInfo['categories'].isNotEmpty)
            ? volumeInfo['categories'].join(', ')
            : '',
        pageCount: volumeInfo['pageCount'] ?? 0,
        externalImageUrl: coverUrl,
        publishedDate: _parsePublishedDate(volumeInfo['publishedDate']),
      );
    } else {
      return null;
    }
  }

  static String getOpenLibraryCoverUrl(String isbn, String size) {
    return 'https://covers.openlibrary.org/b/isbn/$isbn-$size.jpg';
  }

  Timestamp? _parsePublishedDate(String? dateString) {
    if (dateString == null) return null;
    try {
      DateTime date;
      if (dateString.length == 4) {
        date = DateTime(int.parse(dateString));
      } else if (dateString.length == 7) {
        var parts = dateString.split('-');
        date = DateTime(int.parse(parts[0]), int.parse(parts[1]));
      } else {
        date = DateTime.parse(dateString);
      }
      return Timestamp.fromDate(date);
    } catch (e) {
      print('Error parsing date: $e');
      return null;
    }
  }
}