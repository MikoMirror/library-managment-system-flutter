import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../models/book.dart';
import '../../../../core/services/firestore/books_firestore_service.dart';

// Events
abstract class FilterEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class ApplyFilters extends FilterEvent {
  final List<String> genres;
  final List<String> availability;
  final List<String> languages;

  ApplyFilters({
    required this.genres,
    required this.availability,
    required this.languages,
  });

  @override
  List<Object?> get props => [genres, availability, languages];
}

class ClearFilters extends FilterEvent {}

// State
class FilterState extends Equatable {
  final List<String> selectedGenres;
  final List<String> selectedAvailability;
  final List<String> selectedLanguages;
  final List<Book> filteredBooks;
  final bool isFiltering;

  const FilterState({
    this.selectedGenres = const [],
    this.selectedAvailability = const [],
    this.selectedLanguages = const [],
    this.filteredBooks = const [],
    this.isFiltering = false,
  });

  FilterState copyWith({
    List<String>? selectedGenres,
    List<String>? selectedAvailability,
    List<String>? selectedLanguages,
    List<Book>? filteredBooks,
    bool? isFiltering,
  }) {
    return FilterState(
      selectedGenres: selectedGenres ?? this.selectedGenres,
      selectedAvailability: selectedAvailability ?? this.selectedAvailability,
      selectedLanguages: selectedLanguages ?? this.selectedLanguages,
      filteredBooks: filteredBooks ?? this.filteredBooks,
      isFiltering: isFiltering ?? this.isFiltering,
    );
  }

  @override
  List<Object?> get props => [
    selectedGenres,
    selectedAvailability,
    selectedLanguages,
    filteredBooks,
    isFiltering,
  ];
}

// Bloc
class FilterBloc extends Bloc<FilterEvent, FilterState> {
  final BooksFirestoreService booksService;

  FilterBloc({
    required this.booksService,
  }) : super(const FilterState()) {
    on<ApplyFilters>(_onApplyFilters);
    on<ClearFilters>(_onClearFilters);
  }

  Future<void> _onApplyFilters(ApplyFilters event, Emitter<FilterState> emit) async {
    emit(state.copyWith(isFiltering: true));

    try {
      final books = await booksService.getAllBooks().first;
      final filteredBooks = books.where((book) {
        // Genre filter
        if (event.genres.isNotEmpty && 
            !book.categories.any((c) => event.genres.contains(c))) {
          return false;
        }

        // Availability filter
        if (event.availability.isNotEmpty) {
          final isAvailable = book.booksQuantity > 0;
          final wantAvailable = event.availability.contains('Available');
          if (isAvailable != wantAvailable) {
            return false;
          }
        }

        // Language filter
        if (event.languages.isNotEmpty && 
            !event.languages.contains(book.language)) {
          return false;
        }

        return true;
      }).toList();

      emit(state.copyWith(
        selectedGenres: event.genres,
        selectedAvailability: event.availability,
        selectedLanguages: event.languages,
        filteredBooks: filteredBooks,
        isFiltering: false,
      ));
    } catch (e) {
      emit(state.copyWith(isFiltering: false));
    }
  }

  void _onClearFilters(ClearFilters event, Emitter<FilterState> emit) {
    emit(const FilterState());
  }
} 