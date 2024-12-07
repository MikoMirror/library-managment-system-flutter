import 'package:equatable/equatable.dart';
import '../models/book.dart';

abstract class BooksState extends Equatable {
  @override
  List<Object?> get props => [];
}

class BooksInitial extends BooksState {}

class BooksLoading extends BooksState {}

class BooksLoaded extends BooksState {
  final List<Book> books;
  BooksLoaded(this.books);
  
  @override
  List<Object?> get props => [books];
}

class BooksError extends BooksState {
  final String message;
  BooksError(this.message);
  
  @override
  List<Object?> get props => [message];
} 