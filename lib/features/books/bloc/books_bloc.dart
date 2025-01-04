import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/books_repository.dart';
import 'books_event.dart';
import 'books_state.dart';
import '../models/book.dart';
import 'dart:async';

class BooksBloc extends Bloc<BooksEvent, BooksState> {
  final BooksRepository _repository;
  StreamSubscription? _booksSubscription;

  BooksBloc({required BooksRepository repository})
      : _repository = repository,
        super(BooksInitial()) {
    on<LoadBooksEvent>(_onLoadBooks);
    on<SearchBooks>(_onSearchBooks);
    on<DeleteBook>(_onDeleteBook);
  }

  Future<void> _onLoadBooks(LoadBooksEvent event, Emitter<BooksState> emit) async {
    if (state is! BooksLoaded) {
      emit(BooksLoading());
    }
    
    try {
      await emit.forEach(
        _repository.getAllBooks(),
        onData: (List<Book> books) => BooksLoaded(books, sortType: event.sortType),
        onError: (error, stackTrace) => BooksError(error.toString()),
      );
    } catch (e) {
      emit(BooksError(e.toString()));
    }
  }

  Future<void> _onSearchBooks(SearchBooks event, Emitter<BooksState> emit) async {
    emit(BooksLoading());
    try {
      await emit.forEach(
        _repository.searchBooks(event.query),
        onData: (List<Book> books) => BooksLoaded(books, sortType: (state as BooksLoaded?)?.sortType),
        onError: (error, stackTrace) => BooksError(error.toString()),
      );
    } catch (e) {
      emit(BooksError(e.toString()));
    }
  }

  Future<void> _onDeleteBook(DeleteBook event, Emitter<BooksState> emit) async {
    try {
      await _repository.deleteBook(event.bookId);
      add(LoadBooksEvent(sortType: (state as BooksLoaded?)?.sortType));
    } catch (e) {
      emit(BooksError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _booksSubscription?.cancel();
    return super.close();
  }
} 