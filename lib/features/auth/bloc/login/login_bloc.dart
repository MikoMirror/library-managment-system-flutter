import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../auth/auth_bloc.dart';

part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final AuthBloc _authBloc;

  LoginBloc(this._authBloc) : super(LoginInitial()) {
    on<LoginSubmitted>(_onLoginSubmitted);
    on<PasswordVisibilityToggled>(_onPasswordVisibilityToggled);
  }

  void _onLoginSubmitted(
    LoginSubmitted event,
    Emitter<LoginState> emit,
  ) {
    if (!_validateEmail(event.email)) {
      emit(const LoginValidationError('Please enter a valid email'));
      return;
    }

    if (!_validatePassword(event.password)) {
      emit(const LoginValidationError('Password must be at least 6 characters'));
      return;
    }

    _authBloc.add(LoginRequested(event.email, event.password));
  }

  void _onPasswordVisibilityToggled(
    PasswordVisibilityToggled event,
    Emitter<LoginState> emit,
  ) {
    final currentState = state;
    if (currentState is LoginFormState) {
      emit(currentState.copyWith(showPassword: !currentState.showPassword));
    } else {
      emit(const LoginFormState(showPassword: true));
    }
  }

  bool _validateEmail(String email) {
    return email.contains('@') && email.contains('.');
  }

  bool _validatePassword(String password) {
    return password.length >= 6;
  }
} 