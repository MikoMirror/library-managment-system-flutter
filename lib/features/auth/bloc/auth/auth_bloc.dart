import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import 'dart:async';
import '../../../users/models/user_model.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthBloc({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        super(AuthInitial()) {
    on<AuthStateChanged>(
      _onAuthStateChanged,
      transformer: (events, mapper) => events.flatMap(mapper),
    );
    on<LoginRequested>(_onLoginRequested);
    on<LogoutRequested>(_onLogoutRequested);

    add(AuthStateChanged());
  }

  Future<void> _onAuthStateChanged(
    AuthStateChanged event,
    Emitter<AuthState> emit,
  ) async {
    await emit.forEach<User?>(
      _auth.authStateChanges(),
      onData: (user) {
        if (user == null) {
          return AuthInitial();
        }
        emit(AuthLoading());
        
        _firestore
            .collection('users')
            .doc(user.uid)
            .get()
            .then((userDoc) {
          if (userDoc.exists) {
            final userModel = UserModel.fromMap(userDoc.data()!);
            emit(AuthSuccess(userModel));
          }
        }).catchError((e) {
          emit(AuthError(e.toString()));
        });

        return AuthLoading();
      },
    );
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );
      final userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();
      if (userDoc.exists) {
        final userModel = UserModel.fromMap(userDoc.data()!);
        emit(AuthSuccess(userModel));
      } else {
        emit(AuthError('User data not found'));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _auth.signOut();
    emit(AuthInitial());
  }
}