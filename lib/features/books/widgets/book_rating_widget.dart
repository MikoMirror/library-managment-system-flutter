import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/rating/rating_cubit.dart';
import '../cubit/rating/rating_state.dart';
import '../repositories/books_repository.dart';


class BookRatingWidget extends StatelessWidget {
  final String bookId;
  final String userId;

  const BookRatingWidget({
    super.key,
    required this.bookId,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final cubit = RatingCubit(
          bookId: bookId,
          userId: userId,
          repository: context.read<BooksRepository>(),
        );
        // Defer Firestore operation
        WidgetsBinding.instance.addPostFrameCallback((_) {
          cubit.loadRating();
        });
        return cubit;
      },
      child: BlocBuilder<RatingCubit, RatingState>(
        builder: (context, state) {
          if (state is RatingLoading) {
            return const CircularProgressIndicator();
          }
          
          if (state is RatingError) {
            return Text(state.message);
          }
          
          if (state is RatingSuccess) {
            return Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < state.userRating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                      ),
                      onPressed: () => context
                          .read<RatingCubit>()
                          .rateBook(index + 1.0),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                Text(
                  'Average: ${state.averageRating.toStringAsFixed(1)} (${state.totalRatings} ratings)',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            );
          }
          
          return const SizedBox.shrink();
        },
      ),
    );
  }
} 