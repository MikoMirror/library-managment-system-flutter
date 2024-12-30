import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TestModeCubit extends Cubit<bool> {
  static const String _testModeKey = 'test_mode';
  final SharedPreferences _prefs;

  TestModeCubit(this._prefs) : super(_prefs.getBool(_testModeKey) ?? false);

  void toggleTestMode() {
    final newState = !state;
    _prefs.setBool(_testModeKey, newState);
    emit(newState);
  }
}