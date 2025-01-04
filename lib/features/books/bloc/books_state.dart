import 'package:equatable/equatable.dart';
import '../models/book.dart';
import '../enums/sort_type.dart';

abstract class BooksState extends Equatable {
  const BooksState();

  @override
  List<Object?> get props => [];
}

class BooksInitial extends BooksState {}

class BooksLoading extends BooksState {}

class BooksLoaded extends BooksState {
  final List<Book> books;
  final SortType? sortType;

  const BooksLoaded(this.books, {this.sortType});

  @override
  List<Object?> get props => [books, sortType];
}

class BooksError extends BooksState {
  final String message;
  BooksError(this.message);
  
  @override
  List<Object?> get props => [message];
} 