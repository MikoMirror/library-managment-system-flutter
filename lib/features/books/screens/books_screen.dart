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
import '../../../core/widgets/custom_search_bar.dart';
class BooksScreen extends StatefulWidget {
  const BooksScreen({super.key});

  @override
  State<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _searchController = TextEditingController();
  BookViewType _viewType = BookViewType.desktop;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BooksBloc>().add(LoadBooks());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleDeleteBook(BuildContext context, Book book) {
    context.read<BooksBloc>().add(DeleteBook(book.id!));
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    final isPortrait = MediaQuery.of(context).size.height > MediaQuery.of(context).size.width;
    
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        return Scaffold(
          appBar: CustomAppBar(
            title: Text(
              'Books',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: isSmallScreen ? 18 : null,
              ),
            ),
            actions: [
              SizedBox(
                width: MediaQuery.of(context).size.width * (isSmallScreen ? 0.5 : 0.4),
                child: CustomSearchBar(
                  hintText: 'Search books...',
                  onChanged: (query) {
                    if (query.isEmpty) {
                      context.read<BooksBloc>().add(LoadBooks());
                    } else {
                      context.read<BooksBloc>().add(SearchBooks(query));
                    }
                  },
                ),
              ),
              if (!isPortrait && !isSmallScreen)
                IconButton(
                  icon: Icon(
                    _viewType.icon,
                    size: isSmallScreen ? 20 : 24,
                  ),
                  onPressed: () => _toggleViewType(),
                ),
            ],
          ),
          body: BlocBuilder<BooksBloc, BooksState>(
            builder: (context, state) {
              if (state is BooksLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is BooksError) {
                return Center(
                  child: Text(
                    state.message,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
                    ),
                  ),
                );
              }
              if (state is BooksLoaded) {
                return _buildBooksList(context, state.books);
              }
              return const SizedBox.shrink();
            },
          ),
          floatingActionButton: authState is AuthSuccess 
            ? StreamBuilder<DocumentSnapshot>(
                stream: _firestore.collection('users').doc(authState.user.uid).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox.shrink();
                  
                  final userData = snapshot.data!.data() as Map<String, dynamic>?;
                  final isAdmin = userData?['role'] == 'admin';

                  return isAdmin 
                    ? FloatingActionButton(
                        onPressed: () => _showAddBookDialog(context),
                        child: Icon(
                          Icons.add,
                          size: isSmallScreen ? 20 : 24,
                        ),
                      )
                    : const SizedBox.shrink();
                },
              )
            : null,
        );
      },
    );
  }

  Widget _buildBooksList(BuildContext context, List<Book> books) {
    final authState = context.read<AuthBloc>().state;
    final userId = authState is AuthSuccess ? authState.user.uid : '';
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    final isPortrait = MediaQuery.of(context).size.height > MediaQuery.of(context).size.width;
    
    return StreamBuilder<DocumentSnapshot>(
      stream: authState is AuthSuccess 
        ? _firestore.collection('users').doc(authState.user.uid).snapshots()
        : const Stream.empty(),
      builder: (context, snapshot) {
        final isAdmin = snapshot.hasData && 
          (snapshot.data!.data() as Map<String, dynamic>?)?['role'] == 'admin';

        // Use mobile view for small screens or portrait orientation
        if (isSmallScreen || isPortrait) {
          return Padding(
            padding: EdgeInsets.all(isSmallScreen ? 8.0 : 16.0),
            child: MobileBooksGrid(
              books: books,
              userId: userId,
              isAdmin: isAdmin,
              onDeleteBook: _handleDeleteBook,
            ),
          );
        }

        // Use selected view type for landscape orientation on larger screens
        Widget content;
        switch (_viewType) {
          case BookViewType.mobile:
            content = MobileBooksGrid(
              books: books,
              userId: userId,
              isAdmin: isAdmin,
              onDeleteBook: _handleDeleteBook,
            );
            break;
          case BookViewType.table:
            content = TableBooksView(
              books: books,
              userId: userId,
              isAdmin: isAdmin,
              onDeleteBook: _handleDeleteBook,
            );
            break;
          case BookViewType.desktop:
          default:
            content = DesktopBooksGrid(
              books: books,
              userId: userId,
              isAdmin: isAdmin,
              onDeleteBook: _handleDeleteBook,
            );
            break;
        }

        return Padding(
          padding: EdgeInsets.all(isSmallScreen ? 8.0 : 16.0),
          child: content,
        );
      },
    );
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
}