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
import '../enums/book_view_type.dart';
import '../widgets/book card/table_books_view.dart';
import '../../../core/widgets/app_bar.dart';
import 'dart:async';
import '../../books/enums/sort_type.dart';
import '../../../features/books/bloc/books_bloc.dart';
import '../../../features/books/bloc/books_state.dart';
import '../../../features/books/bloc/books_event.dart';
import '../../../core/navigation/cubit/navigation_cubit.dart';

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

class _BooksScreenState extends State<BooksScreen> with SingleTickerProviderStateMixin {
  late final _firestore = FirebaseFirestore.instance;
  late final _searchController = TextEditingController();
  bool _isSearchVisible = false;
  String? _userId;
  bool _isAdmin = false;
  
  late bool _isSmallScreen;
  late bool _isPortrait;
  
  StreamSubscription? _adminStreamSubscription;
  DocumentSnapshot? _adminSnapshot;
  
  BookViewType _viewType = BookViewType.desktop;

  @override
  void initState() {
    super.initState();
    
    // Don't reload books if we already have them and a sort type is specified
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
      
      // First, get the initial admin status synchronously
      FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .get()
          .then((snapshot) {
        if (mounted) {
          final userData = snapshot.data() as Map<String, dynamic>?;
          setState(() {
            _adminSnapshot = snapshot;
            _isAdmin = userData?['role'] == 'admin';
          });
        }
      });

      // Then set up the stream for updates
      _adminStreamSubscription?.cancel();
      _adminStreamSubscription = _firestore
          .collection('users')
          .doc(_userId)
          .snapshots()
          .listen(
        (snapshot) {
          if (mounted) {
            final userData = snapshot.data() as Map<String, dynamic>?;
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final mediaQuery = MediaQuery.of(context);
    _isSmallScreen = mediaQuery.size.width < 600;
    _isPortrait = mediaQuery.orientation == Orientation.portrait;
  }

  @override
  void dispose() {
    _adminStreamSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _toggleViewType() {
    setState(() {
      _viewType = _viewType == BookViewType.desktop 
          ? BookViewType.table 
          : BookViewType.desktop;
    });
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
              actions: [
                IconButton(
                  icon: Icon(_getViewTypeIcon()),
                  onPressed: _toggleViewType,
                ),
              ],
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
      return _buildBooksContent(state.books);
    }
    return const SizedBox.shrink();
  }

  Widget _buildBooksContent(List<Book> books) {
    if (books.isEmpty) {
      return const Center(
        child: Text('No books available'),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (_viewType == BookViewType.table) {
          return TableBooksView(
            books: books,
            userId: _userId ?? '',
            isAdmin: _isAdmin,
            onDeleteBook: _handleDeleteBook,
          );
        }

        return Container(
          constraints: const BoxConstraints(
            minHeight: 0,
            maxHeight: double.infinity,
          ),
          child: _isSmallScreen || _isPortrait
            ? MobileBooksGrid(
                books: books,
                userId: _userId ?? '',
                isAdmin: _isAdmin,
                onDeleteBook: _handleDeleteBook,
                showAdminControls: true,
              )
            : DesktopBooksGrid(
                books: books,
                userId: _userId ?? '',
                isAdmin: _isAdmin,
                onDeleteBook: _handleDeleteBook,
                showAdminControls: true,
              ),
        );
      },
    );
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

  IconData _getViewTypeIcon() {
    switch (_viewType) {
      case BookViewType.mobile:
        return Icons.grid_view;
      case BookViewType.table:
        return Icons.table_rows;
      case BookViewType.desktop:
      default:
        return Icons.dashboard;
    }
  }
}