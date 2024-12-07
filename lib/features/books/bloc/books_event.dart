import 'package:equatable/equatable.dart';

abstract class BooksEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadBooks extends BooksEvent {}

class SearchBooks extends BooksEvent {
  final String query;
  SearchBooks(this.query);
  
  @override
  List<Object?> get props => [query];
}

class DeleteBook extends BooksEvent {
  final String bookId;
  DeleteBook(this.bookId);
  
  @override
  List<Object?> get props => [bookId];
} 