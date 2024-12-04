part of 'login_bloc.dart';

abstract class LoginState extends Equatable {
  const LoginState();

  @override
  List<Object?> get props => [];
}

class LoginInitial extends LoginState {}

class LoginFormState extends LoginState {
  final bool showPassword;

  const LoginFormState({
    this.showPassword = false,
  });

  LoginFormState copyWith({
    bool? showPassword,
  }) {
    return LoginFormState(
      showPassword: showPassword ?? this.showPassword,
    );
  }

  @override
  List<Object?> get props => [showPassword];
}

class LoginValidationError extends LoginState {
  final String message;

  const LoginValidationError(this.message);

  @override
  List<Object?> get props => [message];
} 