import '../../enums/book_view_type.dart';

abstract class ViewState {
  const ViewState();
}

class ViewInitial extends ViewState {}

class ViewLoaded extends ViewState {
  final BookViewType viewType;

  const ViewLoaded(this.viewType);
} 