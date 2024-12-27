import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import '../models/book.dart';
import '../../users/models/user_model.dart';
import '../../../core/services/database/firestore_service.dart';
import 'package:flutter/widgets.dart';

// States
abstract class BookDetailsState {
  const BookDetailsState();
}

class BookDetailsInitial extends BookDetailsState {}

class BookDetailsLoading extends BookDetailsState {}

class BookDetailsLoaded extends BookDetailsState {
  final Book book;
  final UserModel? userModel;

  const BookDetailsLoaded({
    required this.book,
    this.userModel,
  });

  BookDetailsLoaded copyWith({
    Book? book,
    UserModel? userModel,
  }) {
    return BookDetailsLoaded(
      book: book ?? this.book,
      userModel: userModel ?? this.userModel,
    );
  }
}

class BookDetailsError extends BookDetailsState {
  final String message;
  const BookDetailsError(this.message);
}

// Cubit
class BookDetailsCubit extends Cubit<BookDetailsState> {
  final FirestoreService _firestoreService;
  StreamSubscription? _bookSubscription;
  StreamSubscription? _userSubscription;

  BookDetailsCubit({
    required FirestoreService firestoreService,
  }) : _firestoreService = firestoreService,
       super(BookDetailsInitial());

  void initialize(String? bookId, Book? initialBook, String? userId) {
    if (initialBook != null) {
      emit(BookDetailsLoaded(book: initialBook));
      if (userId != null) {
        _subscribeToUserUpdates(userId);
      }
    } else if (bookId != null) {
      _subscribeToBookUpdates(bookId, userId);
    }
  }

  void _subscribeToBookUpdates(String bookId, String? userId) {
    emit(BookDetailsLoading());
    
    _bookSubscription = _firestoreService
        .getBookStream(bookId)
        .listen(
          (snapshot) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              
              if (!snapshot.exists) {
                emit(const BookDetailsError('Book not found'));
                return;
              }

              final bookData = snapshot.data() as Map<String, dynamic>?;
              if (bookData == null) {
                emit(const BookDetailsError('Invalid book data'));
                return;
              }

              final book = Book.fromMap(bookData, snapshot.id);
              emit(BookDetailsLoaded(book: book));

              if (userId != null) {
                _subscribeToUserUpdates(userId);
              }
            });
          },
          onError: (error) => emit(BookDetailsError(error.toString())),
        );
  }

  void _subscribeToUserUpdates(String userId) {
    _userSubscription = _firestoreService
        .getUserStream(userId)
        .listen(
          (snapshot) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              
              if (!snapshot.exists) return;

              final userData = snapshot.data() as Map<String, dynamic>?;
              if (userData == null) return;

              final userModel = UserModel.fromMap(userData);
              final currentState = state;
              
              if (currentState is BookDetailsLoaded) {
                emit(currentState.copyWith(userModel: userModel));
              }
            });
          },
          onError: (error) => emit(BookDetailsError(error.toString())),
        );
  }

  bool get mounted => !isClosed;

  @override
  Future<void> close() {
    _bookSubscription?.cancel();
    _userSubscription?.cancel();
    return super.close();
  }
}