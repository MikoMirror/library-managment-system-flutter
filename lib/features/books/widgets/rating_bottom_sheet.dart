import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/book.dart';
import '../cubit/rating/rating_cubit.dart';
import '../repositories/books_repository.dart';
import '../cubit/rating/rating_state.dart';

class RatingBottomSheet extends StatelessWidget {
  final Book book;
  final String userId;

  const RatingBottomSheet({
    super.key,
    required this.book,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RatingCubit(
        bookId: book.id!,
        userId: userId,
        repository: context.read<BooksRepository>(),
      )..loadRating(),
      child: BlocListener<RatingCubit, RatingState>(
        listener: (context, state) {
          if (state is RatingSuccess) {
            Navigator.pop(context);
          } else if (state is RatingError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        child: _RatingBottomSheetContent(book: book),
      ),
    );
  }
}

class _RatingBottomSheetContent extends StatefulWidget {
  final Book book;

  const _RatingBottomSheetContent({required this.book});

  @override
  State<_RatingBottomSheetContent> createState() => _RatingBottomSheetContentState();
}

class _RatingBottomSheetContentState extends State<_RatingBottomSheetContent> {
  double _rating = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: BlocConsumer<RatingCubit, RatingState>(
              listener: (context, state) {
                if (state is RatingSuccess && _rating == 0) {
                  setState(() {
                    _rating = state.userRating;
                  });
                }
              },
              builder: (context, state) {
                return Column(
                  children: [
                    Text(
                      state is RatingSuccess && state.userRating > 0
                          ? 'Update your rating for "${widget.book.title}"'
                          : 'Rate "${widget.book.title}"',
                      style: theme.textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _rating = index + 1;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: Icon(
                              index < _rating ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 40,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: state is RatingLoading || _rating == 0
                              ? null
                              : () {
                                  context.read<RatingCubit>().rateBook(_rating);
                                },
                          child: state is RatingLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  state is RatingSuccess && state.userRating > 0
                                      ? 'Update'
                                      : 'Submit',
                                ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 