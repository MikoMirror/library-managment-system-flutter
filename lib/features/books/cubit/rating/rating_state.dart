abstract class RatingState {
  const RatingState();
}

class RatingInitial extends RatingState {}

class RatingLoading extends RatingState {}

class RatingSuccess extends RatingState {
  final double userRating;
  final double averageRating;
  final int totalRatings;

  const RatingSuccess({
    required this.userRating,
    required this.averageRating,
    required this.totalRatings,
  });
}

class RatingError extends RatingState {
  final String message;

  const RatingError(this.message);
} 