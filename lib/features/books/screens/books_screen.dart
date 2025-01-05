import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/book.dart';
import '../../auth/bloc/auth/auth_bloc.dart';
import '../widgets/add_book_dialog.dart';
import '../bloc/books_bloc.dart';
import '../bloc/books_state.dart';
import '../bloc/books_event.dart';
import '../widgets/book card/mobile_books_grid.dart';
import '../widgets/book card/desktop_books_grid.dart';
import '../../../core/widgets/app_bar.dart';
import '../../../core/navigation/cubit/navigation_cubit.dart';
import '../../books/enums/sort_type.dart';

class BooksScreen extends StatefulWidget {
  final SortType? sortType;
  final VoidCallback? onBackPressed;
  
  const BooksScreen({
    super.key,
    this.sortType,
    this.onBackPressed,
  });

  @override
  State<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen> {
  late final _firestore = FirebaseFirestore.instance;
  late final _searchController = TextEditingController();
  String? _userId;
  bool _isAdmin = false;
  
  StreamSubscription? _adminStreamSubscription;
  DocumentSnapshot? _adminSnapshot;

  @override
  void initState() {
    super.initState();
    
    if (widget.sortType != null) {
      final state = context.read<BooksBloc>().state;
      if (state is! BooksLoaded) {
        context.read<BooksBloc>().add(LoadBooksEvent(sortType: widget.sortType));
      }
    }
    
    _setupAdminStream();
  }

  void _setupAdminStream() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthSuccess) {
      _userId = authState.user.uid;
      
      FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .get()
          .then((snapshot) {
        if (mounted) {
          final userData = snapshot.data();
          setState(() {
            _adminSnapshot = snapshot;
            _isAdmin = userData?['role'] == 'admin';
          });
        }
      });

      _adminStreamSubscription?.cancel();
      _adminStreamSubscription = _firestore
          .collection('users')
          .doc(_userId)
          .snapshots()
          .listen(
        (snapshot) {
          if (mounted) {
            final userData = snapshot.data();
            setState(() {
              _adminSnapshot = snapshot;
              _isAdmin = userData?['role'] == 'admin';
            });
          }
        },
        onError: (error) {
          debugPrint('Error in admin stream: $error');
        },
      );
    }
  }

  Widget _buildBookGrid(List<Book> books) {
    final mediaQuery = MediaQuery.of(context);
    final isPortrait = mediaQuery.orientation == Orientation.portrait;
    final isSmallScreen = mediaQuery.size.width < 600;

    // Use mobile grid for portrait orientation or small screens
    if (isPortrait || isSmallScreen) {
      return MobileBooksGrid(
        books: books,
        userId: _userId ?? '',
        isAdmin: _isAdmin,
        onDeleteBook: _handleDeleteBook,
        showAdminControls: true,
      );
    }

    // Use desktop grid for landscape orientation on larger screens
    return DesktopBooksGrid(
      books: books,
      userId: _userId ?? '',
      isAdmin: _isAdmin,
      onDeleteBook: _handleDeleteBook,
      showAdminControls: true,
    );
  }

  @override
  void dispose() {
    _adminStreamSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BooksBloc, BooksState>(
      buildWhen: (previous, current) {
        return previous.runtimeType != current.runtimeType ||
            (current is BooksLoaded && previous is BooksLoaded &&
             current.books != previous.books);
      },
      builder: (context, state) {
        return WillPopScope(
          onWillPop: () async {
            context.read<NavigationCubit>().navigateToHome();
            return false;
          },
          child: Scaffold(
            appBar: UnifiedAppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.read<NavigationCubit>().navigateToHome(),
              ),
              title: const Text(
                'Books',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              searchHint: 'Search books...',
              onSearch: (query) {
                if (query.isEmpty) {
                  context.read<BooksBloc>().add(LoadBooksEvent(sortType: widget.sortType));
                } else {
                  context.read<BooksBloc>().add(SearchBooks(query));
                }
              },
            ),
            body: _buildBooksList(state),
            floatingActionButton: _buildFAB(context.read<AuthBloc>().state),
          ),
        );
      },
    );
  }

  Widget _buildBooksList(BooksState state) {
    if (state is BooksLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state is BooksError) {
      return Center(child: Text(state.message));
    }
    if (state is BooksLoaded) {
      return _buildBookGrid(state.books);
    }
    return const SizedBox.shrink();
  }

  Widget _buildFAB(AuthState authState) {
    if (authState is! AuthSuccess) return const SizedBox.shrink();

    final userData = _adminSnapshot?.data() as Map<String, dynamic>?;
    final isAdmin = userData?['role'] == 'admin';

    return isAdmin
        ? FloatingActionButton(
            onPressed: () => _showAddBookDialog(context),
            child: const Icon(Icons.add),
          )
        : const SizedBox.shrink();
  }

  void _handleDeleteBook(BuildContext context, Book book) {
    context.read<BooksBloc>().add(DeleteBook(book.id!));
  }

  Future<void> _showAddBookDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => const AddBookDialog(),
    );
  }
}