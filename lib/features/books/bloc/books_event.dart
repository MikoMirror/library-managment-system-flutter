import 'package:equatable/equatable.dart';
import '../enums/sort_type.dart';

abstract class BooksEvent {
  const BooksEvent();
}

class LoadBooksEvent extends BooksEvent {
  final SortType? sortType;
  
  const LoadBooksEvent({this.sortType});
}

class SearchBooks extends BooksEvent {
  final String query;
  
  const SearchBooks(this.query);
  
  @override
  List<Object?> get props => [query];
}

class DeleteBook extends BooksEvent {
  final String bookId;
  
  const DeleteBook(this.bookId);
  
  @override
  List<Object?> get props => [bookId];
} 