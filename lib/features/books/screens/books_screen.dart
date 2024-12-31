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

class BooksScreen extends StatefulWidget {
  const BooksScreen({super.key});

  @override
  State<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen> with SingleTickerProviderStateMixin {
  late final _firestore = FirebaseFirestore.instance;
  late final _searchController = TextEditingController();
  bool _isSearchVisible = false;
  
  late bool _isSmallScreen;
  late bool _isPortrait;
  
  StreamSubscription? _adminStreamSubscription;
  DocumentSnapshot? _adminSnapshot;
  
  BookViewType _viewType = BookViewType.desktop;

  // Add animation controller
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load books through bloc
      context.read<BooksBloc>().add(LoadBooks());
      
      // Setup admin stream
      _setupAdminStream();
    });
  }

  void _setupAdminStream() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthSuccess) {
      // Cancel existing subscription if any
      _adminStreamSubscription?.cancel();
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _adminStreamSubscription = _firestore
            .collection('users')
            .doc(authState.user.uid)
            .snapshots()
            .listen(
          (snapshot) {
            if (mounted) {
              setState(() {
                _adminSnapshot = snapshot;
              });
            }
          },
          onError: (error) {
            debugPrint('Error in admin stream: $error');
          },
        );
      });
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
    _animationController.dispose();
    _adminStreamSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _handleDeleteBook(BuildContext context, Book book) {
    context.read<BooksBloc>().add(DeleteBook(book.id!));
  }

  Widget? _buildFAB(AuthState authState) {
    if (authState is! AuthSuccess) return null;

    if (_adminSnapshot == null) {
      return const SizedBox.shrink();
    }

    final userData = _adminSnapshot!.data() as Map<String, dynamic>?;
    final isAdmin = userData?['role'] == 'admin';

    return isAdmin 
      ? FloatingActionButton(
          onPressed: () => _showAddBookDialog(context),
          child: Icon(
            Icons.add,
            size: _isSmallScreen ? 20 : 24,
          ),
        )
      : const SizedBox.shrink();
  }

  Widget _buildBooksList(BuildContext context, List<Book> books) {
    final authState = context.read<AuthBloc>().state;
    final userId = authState is AuthSuccess ? authState.user.uid : '';
    
    if (_adminSnapshot == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final userData = _adminSnapshot!.data() as Map<String, dynamic>?;
    final isAdmin = userData?['role'] == 'admin';

    if (_isSmallScreen || _isPortrait) {
      return Padding(
        padding: EdgeInsets.all(_isSmallScreen ? 8.0 : 16.0),
        child: MobileBooksGrid(
          key: ValueKey('mobile-${books.length}'),
          books: books,
          userId: userId,
          isAdmin: isAdmin,
          onDeleteBook: _handleDeleteBook,
        ),
      );
    }

    final content = _buildViewContent(books, userId, isAdmin);
    
    return Padding(
      padding: EdgeInsets.all(_isSmallScreen ? 8.0 : 16.0),
      child: content,
    );
  }

  Widget _buildViewContent(List<Book> books, String userId, bool isAdmin) {
    switch (_viewType) {
      case BookViewType.mobile:
        return MobileBooksGrid(
          key: ValueKey('mobile-${books.length}'),
          books: books,
          userId: userId,
          isAdmin: isAdmin,
          onDeleteBook: _handleDeleteBook,
        );
      case BookViewType.table:
        return TableBooksView(
          key: ValueKey('table-${books.length}'),
          books: books,
          userId: userId,
          isAdmin: isAdmin,
          onDeleteBook: _handleDeleteBook,
        );
      case BookViewType.desktop:
      default:
        return DesktopBooksGrid(
          key: ValueKey('desktop-${books.length}'),
          books: books,
          userId: userId,
          isAdmin: isAdmin,
          onDeleteBook: _handleDeleteBook,
        );
    }
  }

  void _showAddBookDialog(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 16.0 : 40.0,
          vertical: isSmallScreen ? 24.0 : 40.0,
        ),
        child: const AddBookDialog(),
      ),
    );
  }

  void _toggleViewType() {
    setState(() {
      _viewType = BookViewType.values[
        (_viewType.index + 1) % BookViewType.values.length
      ];
    });
  }

  // Add method to toggle search
  void _toggleSearch() {
    setState(() {
        _isSearchVisible = !_isSearchVisible;
        if (_isSearchVisible) {
            _animationController.forward();
        } else {
            _animationController.reverse();
            _searchController.clear();
            context.read<BooksBloc>().add(LoadBooks());
        }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;

    return Scaffold(
      appBar: UnifiedAppBar(
        title: const Text('Books'),
        searchHint: 'Search books...',
        onSearch: (query) {
          context.read<BooksBloc>().add(SearchBooks(query));
        },
        actions: [
          if (!_isSmallScreen && !_isPortrait)
            IconButton(
              icon: Icon(_getViewTypeIcon()),
              onPressed: _toggleViewType,
            ),
        ],
        isSimple: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocBuilder<BooksBloc, BooksState>(
              builder: (context, state) {
                if (state is BooksLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is BooksError) {
                  return Center(child: Text(state.message));
                }
                if (state is BooksLoaded) {
                  return _buildBooksList(context, state.books);
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFAB(authState),
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