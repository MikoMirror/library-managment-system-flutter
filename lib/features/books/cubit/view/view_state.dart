import '../../enums/book_view_type.dart';

abstract class ViewState {}

class ViewInitial extends ViewState {}

class ViewLoaded extends ViewState {
  final BookViewType viewType;

  ViewLoaded(this.viewType);
} 