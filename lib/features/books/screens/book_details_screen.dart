import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/book.dart';
import '../widgets/rating_bottom_sheet.dart';
import '../../auth/bloc/auth/auth_bloc.dart';
import '../cubit/rating/rating_cubit.dart';
import '../cubit/rating/rating_state.dart';
import '../../../features/users/models/user_model.dart';
import '../../../core/services/database/firestore_service.dart';
import '../../../core/services/image/image_cache_service.dart';

class BookDetailsScreen extends StatelessWidget {
  final String? bookId;
  final Book? book;
  final FirestoreService _firestoreService;
  final ImageCacheService _imageCacheService;

  BookDetailsScreen({
    super.key,
    this.bookId,
    this.book,
  })  : assert(bookId != null || book != null, 'Either bookId or book must be provided'),
        _firestoreService = FirestoreService(),
        _imageCacheService = ImageCacheService();

  @override
  Widget build(BuildContext context) {
    if (book != null) {
      _imageCacheService.preCacheBookImages(context, [book!]);
      return Scaffold(
        body: _buildScreenContent(context, book!),
      );
    }

    return Scaffold(
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestoreService.getBookStream(bookId!),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final bookData = snapshot.data!.data() as Map<String, dynamic>?;
          if (bookData == null) {
            return const Center(child: Text('Book not found'));
          }

          final book = Book.fromMap(bookData, snapshot.data!.id);
          return _buildScreenContent(context, book);
        },
      ),
    );
  }

  Widget _buildScreenContent(BuildContext context, Book currentBook) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is! AuthSuccess) {
          return const Center(child: CircularProgressIndicator());
        }

        return StreamBuilder<DocumentSnapshot>(
          stream: _firestoreService.getUserStream(state.user.uid),
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
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
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
                  _buildBackgroundImage(currentBook),
                  _buildGradientOverlay(context),
                  _buildBookContent(context, currentBook),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBackgroundImage(Book currentBook) {
    return Positioned.fill(
      child: _imageCacheService.buildCachedImage(
        imageUrl: currentBook.coverUrl,
        imageBuilder: (context, imageProvider) => Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: imageProvider,
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.5),
                BlendMode.darken,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGradientOverlay(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final overlayColor = isDark ? Colors.black : Colors.white;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            overlayColor.withOpacity(0.1),
            overlayColor.withOpacity(0.3),
            overlayColor.withOpacity(0.7),
            overlayColor.withOpacity(0.95),
          ],
          stops: const [0.0, 0.3, 0.6, 1.0],
        ),
      ),
    );
  }

  Widget _buildBookContent(BuildContext context, Book currentBook) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            _buildBookImage(currentBook),
            const SizedBox(height: 24),
            _buildBookHeader(context, currentBook),
            const SizedBox(height: 24),
            _buildInfoRow(context, currentBook),
            const SizedBox(height: 24),
            _buildDescription(context, currentBook),
          ],
        ),
      ),
    );
  }

  Widget _buildBookImage(Book currentBook) {
    return Hero(
      tag: 'book-${currentBook.id}',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: _imageCacheService.buildCachedImage(
          imageUrl: currentBook.coverUrl,
          width: 150,
          height: 200,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildBookHeader(BuildContext context, Book currentBook) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          currentBook.title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'by ${currentBook.author}',
          style: theme.textTheme.titleMedium,
        ),
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, Book currentBook) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildInfoCard(
          context,
          'Rating',
          '${currentBook.averageRating.toStringAsFixed(1)}/5',
          icon: const Icon(
            Icons.star,
            color: Colors.amber,
            size: 28,
          ),
        ),
        _buildInfoCard(
          context,
          'Pages',
          '${currentBook.pageCount}',
          icon: const Icon(
            Icons.menu_book,
            color: Colors.blue,
            size: 28,
          ),
        ),
        _buildInfoCard(
          context,
          'Language',
          currentBook.language.toUpperCase(),
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

  Widget _buildDescription(BuildContext context, Book currentBook) {
    final theme = Theme.of(context);
    return Card(
      color: theme.cardTheme.color?.withOpacity(0.8),
      elevation: theme.cardTheme.elevation,
      shadowColor: Colors.black,
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
              currentBook.description,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRateButton(BuildContext context, String userId) {
    if (book?.id == null) return const SizedBox.shrink();
    
    return BlocBuilder<RatingCubit, RatingState>(
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
    );
  }

  void _showRatingBottomSheet(BuildContext context, String userId) {
    if (book == null) return;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => BlocProvider.value(
        value: context.read<RatingCubit>(),
        child: RatingBottomSheet(
          book: book!,
          userId: userId,
        ),
      ),
    );
  }
} 