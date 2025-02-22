import '../enums/sort_type.dart';
import '../models/book.dart';

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
  
  List<Object?> get props => [query];
}

class DeleteBook extends BooksEvent {
  final String bookId;
  
  const DeleteBook(this.bookId);
  
  List<Object?> get props => [bookId];
} 