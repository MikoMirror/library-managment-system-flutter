import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../enums/book_view_type.dart';
import 'view_state.dart';

class ViewCubit extends Cubit<ViewState> {
  static const String _viewTypeKey = 'book_view_type';
  
  ViewCubit() : super(ViewInitial()) {
    _loadViewType();
  }

  Future<void> setViewType(BookViewType type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_viewTypeKey, type.name);
    emit(ViewLoaded(type));
  }

  Future<void> _loadViewType() async {
    final prefs = await SharedPreferences.getInstance();
    final savedType = prefs.getString(_viewTypeKey);
    
    final viewType = savedType != null 
        ? BookViewType.values.firstWhere(
            (type) => type.name == savedType,
            orElse: () => BookViewType.desktop,
          )
        : BookViewType.desktop;
    
    emit(ViewLoaded(viewType));
  }
} 