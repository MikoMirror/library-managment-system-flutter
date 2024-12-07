import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/book.dart';
import '../widgets/book_image_widget.dart';
import '../widgets/rating_bottom_sheet.dart';
import '../../auth/bloc/auth/auth_bloc.dart';
import '../cubit/rating/rating_cubit.dart';
import '../cubit/rating/rating_state.dart';
import '../repositories/books_repository.dart';
import '../../../core/theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../features/users/models/user_model.dart';

class BookInfoScreen extends StatelessWidget {
  final Book book;
  static final _firestore = FirebaseFirestore.instance;

  const BookInfoScreen({
    super.key,
    required this.book,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is! AuthSuccess) {
          return const Center(child: CircularProgressIndicator());
        }

        return FutureBuilder<DocumentSnapshot>(
          future: _firestore.collection('users').doc(state.user.uid).get(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final userData = snapshot.data!.data() as Map<String, dynamic>;
            final userModel = UserModel.fromMap(userData);
            final isAdmin = userModel.role == 'admin';

            return Scaffold(
              extendBodyBehindAppBar: true,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                actions: [
                  if (!isAdmin)
                    Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: _buildRateButton(context, userModel.userId),
                    ),
                ],
              ),
              body: Stack(
                children: [
                  _buildBackgroundImage(),
                  _buildGradientOverlay(context),
                  _buildContent(context, state),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBackgroundImage() {
    return Positioned.fill(
      child: Image.network(
        book.coverUrl,
        fit: BoxFit.cover,
        color: Colors.black.withOpacity(0.5),
        colorBlendMode: BlendMode.darken,
      ),
    );
  }

  Widget _buildGradientOverlay(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final overlayColor = isDark ? Colors.black : Colors.white;

    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              overlayColor.withOpacity(0.7),
              overlayColor.withOpacity(0.9),
              overlayColor,
            ],
            stops: const [0.0, 0.4, 0.75, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, AuthSuccess state) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            _buildBookImage(),
            const SizedBox(height: 24),
            _buildBookHeader(context),
            const SizedBox(height: 24),
            _buildInfoRow(context),
            const SizedBox(height: 24),
            _buildDescription(context),
          ],
        ),
      ),
    );
  }

  Widget _buildBookImage() {
    return Hero(
      tag: 'book-${book.id}',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          book.coverUrl,
          height: 200,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildBookHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          book.title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'by ${book.author}',
          style: theme.textTheme.titleMedium,
        ),
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildInfoCard(
          context, 
          'Rating', 
          '${book.averageRating.toStringAsFixed(1)}/5',
          icon: const Icon(
            Icons.star,
            color: Colors.amber,
            size: 28,
          ),
        ),
        _buildInfoCard(
          context, 
          'Pages', 
          '${book.pageCount}',
          icon: const Icon(
            Icons.menu_book,
            color: Colors.blue,
            size: 28,
          ),
        ),
        _buildInfoCard(
          context, 
          'Language', 
          book.language.toUpperCase(),
          icon: const Icon(
            Icons.language,
            color: Colors.green,
            size: 28,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(BuildContext context, String label, String value, {Widget? icon}) {
    final theme = Theme.of(context);
    return Column(
      children: [
        if (icon != null) ...[
          icon,
          const SizedBox(height: 8),
        ],
        Text(
          label,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildDescription(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.cardTheme.color?.withOpacity(0.8),
      elevation: theme.cardTheme.elevation,
      shape: theme.cardTheme.shape,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Synopsis',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              book.description,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRateButton(BuildContext context, String userId) {
    return BlocProvider(
      create: (context) => RatingCubit(
        bookId: book.id!,
        userId: userId,
        repository: context.read<BooksRepository>(),
      )..loadRating(),
      child: BlocBuilder<RatingCubit, RatingState>(
        builder: (context, state) {
          return TextButton.icon(
            icon: Icon(
              state is RatingSuccess && state.userRating > 0
                  ? Icons.star
                  : Icons.star_border,
              color: Colors.white,
            ),
            label: Text(
              'Rate',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                  ),
            ),
            onPressed: () => _showRatingBottomSheet(context, userId),
          );
        },
      ),
    );
  }

  void _showRatingBottomSheet(BuildContext context, String userId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => RatingBottomSheet(
        book: book,
        userId: userId,
      ),
    );
  }
} 