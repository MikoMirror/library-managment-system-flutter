import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/book.dart';
import '../widgets/book_rating_widget.dart';
import '../../auth/bloc/auth/auth_bloc.dart';
import '../cubit/rating/rating_cubit.dart';
import '../cubit/rating/rating_state.dart';
import '../../users/models/user_model.dart';
import '../../../core/services/database/firestore_service.dart';
import '../repositories/books_repository.dart';
import 'book_form_screen.dart';
import '../widgets/book_details/book_header.dart';
import '../widgets/book_details/book_info_row.dart';
import '../widgets/book_details/book_image.dart';
import '../widgets/book_details/book_description.dart';
import '../widgets/book_details/book_quantity.dart';
import '../widgets/rating_bottom_sheet.dart';
import '../../../core/services/image/image_cache_service.dart';

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
  final _firestoreService = FirestoreService();
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

    return StreamBuilder<DocumentSnapshot>(
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

        final book = Book.fromMap(bookData, snapshot.data!.id);
        return _buildContent(book);
      },
    );
  }

  PreferredSizeWidget _buildAppBar(Book book) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
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

                  return Row(
                    children: [
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
                  );
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
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
                colorFilter: ColorFilter.mode(
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
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.3),
              Colors.black.withOpacity(0.7),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildScrollableContent(Book book) {
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
                Colors.black.withOpacity(0.6),
              ],
              stops: const [0.0, 0.3],
            ),
          ),
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
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/reserve',
                          arguments: book,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: const Text(
                        'Reserve Book',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _cachedBook != null
        ? _buildContent(_cachedBook!)
        : _buildStreamContent();
  }

  Widget _buildContent(Book book) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(book),
      body: Stack(
        children: [
          _buildParallaxBackground(book),
          _buildGradientOverlay(),
          _buildScrollableContent(book),
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