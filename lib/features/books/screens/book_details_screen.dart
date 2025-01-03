import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/book.dart';
import '../widgets/book_rating_widget.dart';
import '../../auth/bloc/auth/auth_bloc.dart';
import '../cubit/rating/rating_cubit.dart';
import '../cubit/rating/rating_state.dart';
import '../../users/models/user_model.dart';
import '../../../core/services/firestore/books_firestore_service.dart';
import '../repositories/books_repository.dart';
import 'book_form_screen.dart';
import '../widgets/book_details/book_header.dart';
import '../widgets/book_details/book_info_row.dart';
import '../widgets/book_details/book_description.dart';
import '../widgets/book_details/book_quantity.dart';
import '../../../core/services/image/image_cache_service.dart';
import '../cubit/book_details_cubit.dart';
import '../widgets/book_reservation_dialog.dart';
import '../../../core/services/firestore/users_firestore_service.dart';

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
  final _booksService = BooksFirestoreService();
  final _usersService = UsersFirestoreService();
  final _imageCacheService = ImageCacheService();
  final _scrollController = ScrollController();
  double _scrollOffset = 0.0;
  Book? _cachedBook;
  bool _isLoading = false;
  Widget? _cachedBackground;
  bool _scrollUpdateThrottle = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScrollThrottled);
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    if (widget.book != null) {
      _cachedBook = widget.book;
      setState(() => _isLoading = true);
      
      _imageCacheService.preCacheBookImages(context, [widget.book!]).then((_) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      });

      _imageCacheService.trackBookView(widget.book!);
    }
  }

  void _onScrollThrottled() {
    if (!_scrollUpdateThrottle) {
      _scrollUpdateThrottle = true;
      _scrollOffset = _scrollController.offset;
      setState(() {});
      Future.delayed(const Duration(milliseconds: 16), () {
        _scrollUpdateThrottle = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildStreamContent() {
    if (widget.bookId == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _booksService.getDocumentStream(widget.bookId!),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final bookData = snapshot.data!.data();
        if (bookData == null) {
          return const Center(child: Text('Book not found'));
        }

        final book = Book.fromMap(bookData, snapshot.data!.id);
        return _buildContent(book, null);
      },
    );
  }

  PreferredSizeWidget _buildAppBar(Book book, UserModel? userModel) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        if (userModel != null) ...[
          if (userModel.role == 'admin')
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () => _navigateToEditBook(context, book),
            ),
          if (userModel.role != 'admin')
            IconButton(
              icon: const Icon(Icons.star, color: Colors.white),
              onPressed: () => _showRatingDialog(
                context,
                userModel.userId,
                book.id!,
              ),
            ),
        ],
        const SizedBox(width: 8),
      ],
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

  void _navigateToEditBook(BuildContext context, Book book) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookFormScreen(
          collectionId: 'books',
          book: book,
          mode: FormMode.edit,
        ),
      ),
    ).then((_) {
      setState(() {});
    });
  }

  Widget _buildParallaxBackground(Book book) {
    _cachedBackground ??= RepaintBoundary(
      child: Hero(
        tag: 'book_cover_${book.id}',
        child: _imageCacheService.buildCachedImage(
          imageUrl: book.coverUrl,
          fit: BoxFit.cover,
          imageBuilder: (context, imageProvider) => Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: imageProvider,
                fit: BoxFit.cover,
                colorFilter: const ColorFilter.mode(
                  Colors.black45,
                  BlendMode.darken,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    return Positioned.fill(
      child: Transform.scale(
        scale: 1 + (_scrollOffset * 0.0005),
        child: _cachedBackground!,
      ),
    );
  }

  Widget _buildGradientOverlay() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final overlayColor = isDark ? Colors.black : Colors.white;
    
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              overlayColor.withAlpha(200),
              overlayColor.withAlpha(255),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildScrollableContent(Book book, UserModel? userModel) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final overlayColor = isDark ? Colors.black : Colors.white;
    
    return RepaintBoundary(
      child: SingleChildScrollView(
        controller: _scrollController,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                overlayColor.withOpacity(0.6),
              ],
              stops: const [0.0, 0.3],
            ),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: kToolbarHeight + 32),
                    RepaintBoundary(
                      child: Hero(
                        tag: 'book_image_${book.id}',
                        child: Material(
                          type: MaterialType.transparency,
                          child: _imageCacheService.buildCachedImage(
                            imageUrl: book.coverUrl,
                            width: 200,
                            height: 300,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    RepaintBoundary(child: BookHeader(book: book)),
                    const SizedBox(height: 24),
                    RepaintBoundary(child: BookInfoRow(book: book)),
                    const SizedBox(height: 24),
                    RepaintBoundary(child: BookQuantity(book: book)),
                    const SizedBox(height: 24),
                    RepaintBoundary(child: BookDescription(book: book)),
                    const SizedBox(height: 32),
                    if (book.booksQuantity > 0)
                      RepaintBoundary(
                        child: SizedBox(
                          width: 300,
                          child: ElevatedButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => BookBookingDialog(
                                  book: book,
                                  isAdmin: userModel?.role == 'admin',
                                  userId: userModel?.userId ?? '',
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                            ),
                            child: const Text(
                              'Reserve Book',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => BookDetailsCubit(
        booksService: _booksService,
        usersService: _usersService,
      )..initialize(
          widget.bookId,
          widget.book,
          context.read<AuthBloc>().state is AuthSuccess
              ? (context.read<AuthBloc>().state as AuthSuccess).user.uid
              : null,
        ),
      child: BlocBuilder<BookDetailsCubit, BookDetailsState>(
        builder: (context, state) {
          if (state is BookDetailsLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          
          if (state is BookDetailsError) {
            return Scaffold(
              body: Center(child: Text(state.message)),
            );
          }
          
          if (state is BookDetailsLoaded) {
            return _buildContent(state.book, state.userModel);
          }
          
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildContent(Book book, UserModel? userModel) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(book, userModel),
      body: Stack(
        children: [
          _buildParallaxBackground(book),
          _buildGradientOverlay(),
          _buildScrollableContent(book, userModel),
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}