import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';


class ThemeState {
  final bool isDarkMode;

  ThemeState({
    required this.isDarkMode,
  });

  ThemeState copyWith({
    bool? isDarkMode,
  }) {
    return ThemeState(
      isDarkMode: isDarkMode ?? this.isDarkMode,
    );
  }
}

class ThemeCubit extends Cubit<ThemeState> {
  static const _themeKey = 'isDarkMode';

  ThemeCubit() : super(ThemeState(isDarkMode: false)) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDarkMode = prefs.getBool(_themeKey) ?? false;
    emit(ThemeState(isDarkMode: isDarkMode));
  }

  Future<void> toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, !state.isDarkMode);
    emit(state.copyWith(isDarkMode: !state.isDarkMode));
  }
}