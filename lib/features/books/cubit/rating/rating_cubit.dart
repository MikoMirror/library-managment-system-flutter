import 'package:flutter_bloc/flutter_bloc.dart';
import 'rating_state.dart';
import '../../repositories/books_repository.dart';


class RatingCubit extends Cubit<RatingState> {
  final BooksRepository _repository;
  final String bookId;
  final String userId;

  RatingCubit({
    required this.bookId,
    required this.userId,
    required BooksRepository repository,
  }) : _repository = repository,
       super(RatingInitial());

  Future<void> loadRating() async {
    emit(RatingLoading());
    try {
      final ratings = await _repository.getBookRatings(bookId);
      final userRating = ratings[userId] ?? 0;
      final averageRating = _calculateAverageRating(ratings);

      emit(RatingSuccess(
        userRating: userRating,
        averageRating: averageRating,
        totalRatings: ratings.length,
      ));
    } catch (e) {
      emit(RatingError('Failed to load rating: $e'));
    }
  }

  Future<void> rateBook(double rating) async {
    final currentState = state;
    emit(RatingLoading());
    
    try {
      await _repository.rateBook(bookId, userId, rating);
      await loadRating();
    } catch (e) {
      emit(RatingError('Failed to update rating: $e'));
      if (currentState is RatingSuccess) {
        emit(currentState);
      }
    }
  }

  double _calculateAverageRating(Map<String, double> ratings) {
    if (ratings.isEmpty) return 0;
    final sum = ratings.values.reduce((a, b) => a + b);
    return sum / ratings.length;
  }
} 