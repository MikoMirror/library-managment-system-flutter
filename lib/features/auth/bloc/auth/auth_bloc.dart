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
    _authStateSubscription = _auth.authStateChanges().listen(
      (User? user) {
        if (user != null) {
          add(AuthStateChanged());
        } else {
          add(AuthStateChanged());
        }
      },
      onError: (error) {
        add(AuthErrorEvent(error.toString()));
      },
    );

    on<LoginRequested>((event, emit) async {
      try {
        emit(AuthLoading());
        await _auth.signInWithEmailAndPassword(
          email: event.email,
          password: event.password,
        );
      } catch (e) {
        emit(AuthError(e.toString()));
      }
    });

    on<LogoutRequested>((event, emit) async {
      try {
        await _auth.signOut();
      } catch (e) {
        emit(AuthError(e.toString()));
      }
    });

    on<AuthStateChanged>((event, emit) {
      final user = _auth.currentUser;
      if (user != null) {
        emit(AuthSuccess(user));
      } else {
        emit(AuthInitial());
      }
    });
  }

  @override
  Future<void> close() {
    _authStateSubscription?.cancel();
    return super.close();
  }
}