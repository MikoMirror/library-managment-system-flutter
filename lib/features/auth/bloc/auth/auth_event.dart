part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  
  @override
  List<Object?> get props => [];
}

class CheckAuthStatus extends AuthEvent {}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;

  const LoginRequested(this.email, this.password);

  @override
  List<Object?> get props => [email, password];
}

class LogoutRequested extends AuthEvent {}

class AuthStateChanged extends AuthEvent {
  final User? user;
  
  const AuthStateChanged(this.user);
  
  @override
  List<Object?> get props => [user];
}

class AuthErrorEvent extends AuthEvent {
  final String message;
  
  const AuthErrorEvent(this.message);
  
  @override
  List<Object?> get props => [message];
}