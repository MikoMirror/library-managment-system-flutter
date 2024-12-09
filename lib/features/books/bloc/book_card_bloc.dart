import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/books_repository.dart';

abstract class BookCardEvent {}

class ToggleFavorite extends BookCardEvent {
  final String userId;
  final String bookId;

  ToggleFavorite(this.userId, this.bookId);
}

class LoadFavoriteStatus extends BookCardEvent {
  final String userId;
  final String bookId;

  LoadFavoriteStatus(this.userId, this.bookId);
}

abstract class BookCardState {}

class BookCardInitial extends BookCardState {}

class FavoriteStatusLoaded extends BookCardState {
  final bool isFavorite;

  FavoriteStatusLoaded(this.isFavorite);
}

class BookCardError extends BookCardState {
  final String message;

  BookCardError(this.message);
}

class BookCardBloc extends Bloc<BookCardEvent, BookCardState> {
  final BooksRepository _repository;

  BookCardBloc(this._repository) : super(BookCardInitial()) {
    on<LoadFavoriteStatus>(_onLoadFavoriteStatus);
    on<ToggleFavorite>(_onToggleFavorite);
  }

  Future<void> _onLoadFavoriteStatus(
      LoadFavoriteStatus event, Emitter<BookCardState> emit) async {
    try {
      await Future(() async {
        final isFavorite = await _repository.getFavoriteStatus(event.userId, event.bookId);
        emit(FavoriteStatusLoaded(isFavorite));
      });
    } catch (e) {
      emit(BookCardError(e.toString()));
    }
  }

  Future<void> _onToggleFavorite(
      ToggleFavorite event, Emitter<BookCardState> emit) async {
    try {
      await Future(() async {
        await _repository.toggleFavorite(event.userId, event.bookId);
        add(LoadFavoriteStatus(event.userId, event.bookId)); // Reload status
      });
    } catch (e) {
      emit(BookCardError(e.toString()));
    }
  }
} 