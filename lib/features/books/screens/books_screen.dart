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
import '../../../core/widgets/custom_app_bar.dart';

class BooksScreen extends StatefulWidget {
  const BooksScreen({super.key});

  @override
  State<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen> {
  late final _firestore = FirebaseFirestore.instance;
  late final _searchController = TextEditingController();
  
  late bool _isSmallScreen;
  late bool _isPortrait;
  
  Stream<DocumentSnapshot>? _adminCheckStream;
  
  BookViewType _viewType = BookViewType.desktop;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BooksBloc>().add(LoadBooks());
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final mediaQuery = MediaQuery.of(context);
    _isSmallScreen = mediaQuery.size.width < 600;
    _isPortrait = mediaQuery.orientation == Orientation.portrait;
    
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthSuccess && _adminCheckStream == null) {
      _adminCheckStream = _firestore
          .collection('users')
          .doc(authState.user.uid)
          .snapshots();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleDeleteBook(BuildContext context, Book book) {
    context.read<BooksBloc>().add(DeleteBook(book.id!));
  }

  Widget? _buildFAB(AuthState authState) {
    if (authState is! AuthSuccess) return null;

    return StreamBuilder<DocumentSnapshot>(
      stream: _adminCheckStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        
        final userData = snapshot.data!.data() as Map<String, dynamic>?;
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
      },
    );
  }

  Widget _buildBooksList(BuildContext context, List<Book> books) {
    final authState = context.read<AuthBloc>().state;
    final userId = authState is AuthSuccess ? authState.user.uid : '';
    
    return StreamBuilder<DocumentSnapshot>(
      stream: _adminCheckStream,
      builder: (context, snapshot) {
        final isAdmin = snapshot.hasData && 
          (snapshot.data!.data() as Map<String, dynamic>?)?['role'] == 'admin';

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
      },
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

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;

    return Scaffold(
      appBar: CustomAppBar(
        title: const Text('Books'),
        actions: !_isSmallScreen && !_isPortrait 
          ? [
              IconButton(
                icon: Icon(_getViewTypeIcon()),
                onPressed: _toggleViewType,
              ),
            ]
          : null,
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