import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/services/firestore/users_firestore_service.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UsersFirestoreService _usersService = UsersFirestoreService();
  StreamSubscription<User?>? _authStateSubscription;

  AuthBloc() : super(AuthInitial()) {
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<LoginRequested>(_onLoginRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<AuthStateChanged>(_onAuthStateChanged);

    _authStateSubscription = _auth.authStateChanges().listen(
      (User? user) {
        add(AuthStateChanged(user));
      },
    );
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final currentUser = _auth.currentUser;
      
      if (currentUser != null) {
        // Check if user exists in Firestore
        final userDoc = await _usersService.getUserById(currentUser.uid);
        
        if (userDoc == null) {
          // User exists in Auth but not in Firestore - sign out
          await _auth.signOut();
          emit(AuthInitial());
          return;
        }
        
        emit(AuthSuccess(currentUser));
      } else {
        emit(AuthInitial());
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(AuthLoading());
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );
      if (userCredential.user != null) {
        emit(AuthSuccess(userCredential.user!));
      } else {
        emit(const AuthError('Login failed'));
      }
    } on FirebaseAuthException catch (e) {
      emit(AuthError(e.message ?? 'Authentication failed'));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _auth.signOut();
    emit(const AuthUnauthenticated());
  }

  void _onAuthStateChanged(
    AuthStateChanged event,
    Emitter<AuthState> emit,
  ) {
    if (event.user != null) {
      emit(AuthSuccess(event.user!));
    } else {
      emit(const AuthUnauthenticated());
    }
  }

  @override
  Future<void> close() {
    _authStateSubscription?.cancel();
    return super.close();
  }
}