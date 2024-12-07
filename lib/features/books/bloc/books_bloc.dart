import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/books_repository.dart';
import 'books_event.dart';
import 'books_state.dart';
   import '../models/book.dart';

class BooksBloc extends Bloc<BooksEvent, BooksState> {
  final BooksRepository _repository;

  BooksBloc({required BooksRepository repository})
      : _repository = repository,
        super(BooksInitial()) {
    on<LoadBooks>(_onLoadBooks);
    on<SearchBooks>(_onSearchBooks);
    on<DeleteBook>(_onDeleteBook);
  }

  Future<void> _onLoadBooks(LoadBooks event, Emitter<BooksState> emit) async {
    emit(BooksLoading());
    try {
      await emit.forEach(
        _repository.getAllBooks(),
        onData: (snapshot) {
          final books = snapshot.docs
              .map((doc) => Book.fromMap(
                    doc.data() as Map<String, dynamic>,
                    doc.id,
                  ))
              .toList();
          return BooksLoaded(books);
        },
        onError: (error, stackTrace) => BooksError(error.toString()),
      );
    } catch (e) {
      emit(BooksError(e.toString()));
    }
  }

  Future<void> _onSearchBooks(SearchBooks event, Emitter<BooksState> emit) async {
    emit(BooksLoading());
    try {
      // Implement search logic using repository
    } catch (e) {
      emit(BooksError(e.toString()));
    }
  }

  Future<void> _onDeleteBook(DeleteBook event, Emitter<BooksState> emit) async {
    try {
      await _repository.deleteBook(event.bookId);
    } catch (e) {
      emit(BooksError(e.toString()));
    }
  }
} 