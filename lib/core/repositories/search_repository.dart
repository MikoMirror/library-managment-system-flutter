import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore/search_service.dart';
import '../../features/books/models/book.dart';
import '../../features/users/models/user_model.dart';
import '../../features/reservation/models/reservation.dart';

enum SearchType { books, users, reservations, favorites }

class SearchRepository {
  final SearchService _searchService;

  SearchRepository(this._searchService);

  Stream<List<dynamic>> search({
    required String query,
    required SearchType type,
    Map<String, dynamic>? filters,
  }) {
    return _searchService
        .search(
          collection: _getCollectionName(type),
          query: query,
          searchFields: _getSearchFields(type),
          additionalFilters: filters,
        )
        .map((snapshot) => _mapResults(snapshot, type));
  }

  String _getCollectionName(SearchType type) {
    switch (type) {
      case SearchType.books:
        return 'books';
      case SearchType.users:
        return 'users';
      case SearchType.reservations:
        return 'books_reservation';
      case SearchType.favorites:
        return 'favorites';
    }
  }

  List<String> _getSearchFields(SearchType type) {
    switch (type) {
      case SearchType.books:
        return ['title', 'author', 'isbn'];
      case SearchType.users:
        return ['name', 'email', 'libraryNumber'];
      case SearchType.reservations:
        return ['bookId', 'userId'];
      case SearchType.favorites:
        return ['bookId'];
    }
  }

  List<dynamic> _mapResults(QuerySnapshot snapshot, SearchType type) {
    switch (type) {
      case SearchType.books:
        return snapshot.docs
            .map((doc) => Book.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList();
      case SearchType.users:
        return snapshot.docs
            .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList();
      case SearchType.reservations:
        return snapshot.docs
            .map((doc) => Reservation.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList();
      case SearchType.favorites:
        return snapshot.docs.map((doc) => doc.id).toList();
    }
  }
} 