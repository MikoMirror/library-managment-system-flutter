import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/search_repository.dart';

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

  SearchState copyWith({
    bool? isLoading,
    List<dynamic>? results,
    String? error,
    SearchType? type,
  }) {
    return SearchState(
      isLoading: isLoading ?? this.isLoading,
      results: results ?? this.results,
      error: error ?? this.error,
      type: type ?? this.type,
    );
  }
}

class SearchBloc extends Cubit<SearchState> {
  final SearchRepository _searchRepository;

  SearchBloc(this._searchRepository) : super(SearchState(type: SearchType.books));

  void search({
    required String query,
    required SearchType type,
    Map<String, dynamic>? filters,
  }) {
    emit(state.copyWith(isLoading: true, type: type));

    _searchRepository
        .search(
          query: query,
          type: type,
          filters: filters,
        )
        .listen(
          (results) => emit(state.copyWith(
            isLoading: false,
            results: results,
          )),
          onError: (error) => emit(state.copyWith(
            isLoading: false,
            error: error.toString(),
          )),
        );
  }

  void clearSearch() {
    emit(state.copyWith(
      results: [],
      error: '',
      isLoading: false,
    ));
  }
} 