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
import '../../reservation/widgets/book_reservation_dialog.dart';
import 'dart:ui';
import '../../../features/books/repositories/books_repository.dart';
import '../widgets/book_rating_widget.dart';
import '../bloc/books_bloc.dart';
import '../bloc/books_state.dart';
import 'dart:math' show max;
import '../../../core/theme/app_theme.dart';


class BookDetailsScreen extends StatefulWidget {
  final String? bookId;
  final Book? book;

  const BookDetailsScreen({
    super.key,
    this.bookId,
    this.book,
  }) : assert(bookId != null || book != null, 'Either bookId or book must be provided');

  @override
  State<BookDetailsScreen> createState() => _BookDetailsScreenState();
}

class _BookDetailsScreenState extends State<BookDetailsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final ImageCacheService _imageCacheService = ImageCacheService();
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    setState(() {
      _scrollOffset = _scrollController.offset;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.book != null) {
      _imageCacheService.preCacheBookImages(context, [widget.book!]);
      return _buildScaffold(context, widget.book!);
    }

    return BlocBuilder<BooksBloc, BooksState>(
      builder: (context, booksState) {
        if (booksState is BooksLoaded) {
          final currentBook = booksState.books.firstWhere(
            (b) => b.id == widget.bookId,
            orElse: () => throw Exception('Book not found'),
          );
          return _buildScaffold(context, currentBook);
        }

        // If we don't have the book in BooksBloc, use Firestore stream
        return Scaffold(
          body: StreamBuilder<DocumentSnapshot>(
            stream: _firestoreService.getBookStream(widget.bookId!),
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

              final currentBook = Book.fromMap(bookData, snapshot.data!.id);
              return _buildScaffold(context, currentBook);
            },
          ),
        );
      },
    );
  }

  Widget _buildScaffold(BuildContext context, Book currentBook) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is AuthSuccess) {
                return StreamBuilder<DocumentSnapshot>(
                  stream: _firestoreService.getUserStream(state.user.uid),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox.shrink();
                    
                    final userData = snapshot.data!.data() as Map<String, dynamic>;
                    final userModel = UserModel.fromMap(userData);
                    
                    return TextButton.icon(
                      icon: const Icon(
                        Icons.star_border,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Rate this book',
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: () => _showRatingDialog(
                        context,
                        userModel.userId,
                        currentBook.id!,
                      ),
                    );
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // Parallax background
          Transform.translate(
            offset: Offset(0.0, -_scrollOffset * 0.5),
            child: _buildBackgroundImage(context, currentBook),
          ),
          // Endless gradient overlay
          Container(
            height: MediaQuery.of(context).size.height * 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.5),
                  Colors.black.withOpacity(0.8),
                  Colors.black,
                  Colors.black,
                ],
                stops: const [0.0, 0.2, 0.4, 0.6, 1.0],
              ),
            ),
          ),
          // Scrollable content
          SingleChildScrollView(
            controller: _scrollController,
            physics: const ClampingScrollPhysics(),
            child: Column(
              children: [
                SizedBox(height: MediaQuery.of(context).padding.top),
                _buildBookContent(context, currentBook),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showRatingDialog(BuildContext context, String userId, String bookId) {
    showModalBottomSheet(
      context: context,
      builder: (context) => BlocProvider(
        create: (context) => RatingCubit(
          bookId: bookId,
          userId: userId,
          repository: context.read<BooksRepository>(),
        )..loadRating(),
        child: BlocBuilder<RatingCubit, RatingState>(
          builder: (context, state) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Rate this book',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  BookRatingWidget(
                    bookId: bookId,
                    userId: userId,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBackgroundImage(BuildContext context, Book currentBook) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 1.5,
      child: _imageCacheService.buildCachedImage(
        imageUrl: currentBook.coverUrl,
        imageBuilder: (context, imageProvider) => Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: imageProvider,
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.1),
                BlendMode.darken,
              ),
            ),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 5.0,
              sigmaY: 5.0,
            ),
            child: Container(
              color: Colors.black.withOpacity(0.1),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookImage(Book currentBook) {
    return Hero(
      tag: 'book-${currentBook.id}',
      child: _imageCacheService.buildCachedImage(
        imageUrl: currentBook.coverUrl,
        width: 240,
        height: 360,
        fit: BoxFit.contain,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Add max width constraint for info boxes
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 600),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: _buildInfoBox(
                  context,
                  'Rating',
                  '${currentBook.averageRating.toStringAsFixed(1)}/5',
                  const Icon(
                    Icons.star,
                    color: Colors.amber,
                    size: 28,
                  ),
                  isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoBox(
                  context,
                  'Pages',
                  '${currentBook.pageCount}',
                  const Icon(
                    Icons.menu_book,
                    color: Colors.blue,
                    size: 28,
                  ),
                  isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoBox(
                  context,
                  'Language',
                  currentBook.language.toUpperCase(),
                  const Icon(
                    Icons.language,
                    color: Colors.green,
                    size: 28,
                  ),
                  isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildIsbnBox(context, currentBook.isbn ?? 'N/A', isDark),
        ],
      ),
    );
  }

  Widget _buildInfoBox(BuildContext context, String label, String value, Widget icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark 
            ? AppTheme.darkGradient1.withOpacity(0.7)
            : AppTheme.primaryLight.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark 
              ? AppTheme.darkGradient3.withOpacity(0.5)
              : AppTheme.primaryLight.withOpacity(0.9),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildIsbnBox(BuildContext context, String isbn, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: isDark 
            ? AppTheme.darkGradient1.withOpacity(0.7)
            : AppTheme.primaryLight.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark 
              ? AppTheme.darkGradient3.withOpacity(0.5)
              : AppTheme.primaryLight.withOpacity(0.9),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.qr_code,
            color: Colors.purple,
            size: 28,
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ISBN',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isbn,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ],
      ),
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
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              currentBook.description,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, Book book, bool isAdmin, String userId) {
    // Add max width constraint for buttons
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.book),
              label: const Text('Reserve Book'),
              onPressed: book.booksQuantity > 0
                  ? () => _showBookingDialog(context, book, isAdmin, userId)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showBookingDialog(BuildContext context, Book book, bool isAdmin, String userId) {
    showDialog(
      context: context,
      builder: (context) => BookBookingDialog(
        book: book,
        isAdmin: isAdmin,
        userId: userId,
      ),
    );
  }

  Widget _buildBookContent(BuildContext context, Book currentBook) {
    // Add max width constraint for desktop
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 100), // Extra padding for AppBar
              _buildBookImage(currentBook),
              const SizedBox(height: 24),
              _buildBookHeader(context, currentBook),
              const SizedBox(height: 24),
              _buildInfoRow(context, currentBook),
              const SizedBox(height: 24),
              _buildDescription(context, currentBook),
              const SizedBox(height: 24),
              // Book quantity display
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Books available in library: ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${currentBook.booksQuantity}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: currentBook.booksQuantity > 0 
                            ? Colors.green 
                            : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Reserve button
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  if (state is AuthSuccess) {
                    return StreamBuilder<DocumentSnapshot>(
                      stream: _firestoreService.getUserStream(state.user.uid),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const CircularProgressIndicator();
                        }
                        final userData = snapshot.data!.data() as Map<String, dynamic>;
                        final userModel = UserModel.fromMap(userData);
                        return _buildActionButtons(
                          context, 
                          currentBook, 
                          userModel.role == 'admin',
                          userModel.userId,
                        );
                      },
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
} 