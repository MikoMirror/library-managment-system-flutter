import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription<User?>? _authStateSubscription;

  AuthBloc() : super(AuthInitial()) {
    on<CheckAuthStatus>((event, emit) async {
      emit(AuthLoading());
      final user = _auth.currentUser;
      if (user != null) {
        emit(AuthSuccess(user));
      } else {
        emit(const AuthUnauthenticated());
      }
    });

    on<LoginRequested>((event, emit) async {
      emit(AuthLoading());
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );
      if (userCredential.user != null) {
        emit(AuthSuccess(userCredential.user!));
      } else {
        emit(const AuthUnauthenticated());
      }
    });

    on<LogoutRequested>((event, emit) async {
      await _auth.signOut();
      emit(const AuthUnauthenticated());
    });

    _authStateSubscription = _auth.authStateChanges().listen(
      (User? user) {
        if (user != null) {
          emit(AuthSuccess(user));
        } else {
          emit(const AuthUnauthenticated());
        }
      },
    );

    add(CheckAuthStatus());
  }

  @override
  Future<void> close() {
    _authStateSubscription?.cancel();
    return super.close();
  }
}