import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../features/books/models/book.dart';
import '../../../features/users/models/user_model.dart';
import '../../../features/reservation/models/reservation.dart';
import '../../services/firestore/search_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum SearchType { books, users, reservations, favorites }

class SearchState {
  final bool isLoading;
  final List<dynamic> results;
  final String error;
  final SearchType type;

  SearchState({
    this.isLoading = false,
    this.results = const [],
    this.error = '',
    required this.type,
  });
}

class SearchBloc extends Cubit<SearchState> {
  final SearchService _searchService;

  SearchBloc(this._searchService) : super(SearchState(type: SearchType.books));

  void search({
    required String query,
    required SearchType type,
    Map<String, dynamic>? filters,
  }) {
    emit(SearchState(isLoading: true, type: type));

    final collection = _getCollectionName(type);
    final searchFields = _getSearchFields(type);

    _searchService
        .search(
          collection: collection,
          query: query,
          searchFields: searchFields,
          additionalFilters: filters,
        )
        .listen(
          (snapshot) => emit(SearchState(
            type: type,
            results: _mapResults(snapshot, type),
          )),
          onError: (error) => emit(SearchState(
            type: type,
            error: error.toString(),
          )),
        );
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