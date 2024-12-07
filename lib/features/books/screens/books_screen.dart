import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../models/book.dart';
import '../../auth/bloc/auth/auth_bloc.dart';
import '../widgets/add_book_dialog.dart';
import '../bloc/books_bloc.dart';
import '../bloc/books_state.dart';
import '../bloc/books_event.dart';
import '../widgets/book card/mobile_books_grid.dart';
import '../widgets/book card/desktop_books_grid.dart';
import '../widgets/book card/book_card.dart';
import '../repositories/books_repository.dart';
import '../enums/book_view_type.dart';
import '../widgets/book card/table_books_view.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../features/users/models/user_model.dart';


class BooksScreen extends StatefulWidget {
  const BooksScreen({super.key});

  @override
  State<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen> {
  final _firestore = FirebaseFirestore.instance;
  BookViewType _viewType = BookViewType.desktop;

  @override
  void initState() {
    super.initState();
    context.read<BooksBloc>().add(LoadBooks());
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    return Scaffold(
      appBar: CustomAppBar(
        title: const Text('Books'),
        actions: [
          if (!isMobile) _buildViewSwitcher(context),
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is! AuthSuccess) return const SizedBox.shrink();

              return FutureBuilder<DocumentSnapshot>(
                future: _firestore.collection('users').doc(state.user.uid).get(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox.shrink();

                  final userData = snapshot.data!.data() as Map<String, dynamic>;
                  final userModel = UserModel.fromMap(userData);
                  
                  if (userModel.role != 'admin') return const SizedBox.shrink();
                  
                  return Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return const AddBookDialog();
                          },
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add Book'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          return BlocBuilder<BooksBloc, BooksState>(
            builder: (context, state) {
              if (state is BooksLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is BooksError) {
                return Center(child: Text(state.message));
              }

              if (state is BooksLoaded && authState is AuthSuccess) {
                if (isMobile) {
                  return MobileBooksGrid(
                    books: state.books,
                    user: authState.user,
                    onDeleteBook: _showDeleteConfirmationDialog,
                  );
                }
                
                return _buildBooksList(state.books, authState.user);
              }

              return const Center(child: Text('No books found'));
            },
          );
        },
      ),
    );
  }

  Widget _buildViewSwitcher(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<BookViewType>(
          value: _viewType,
          icon: const Icon(Icons.arrow_drop_down),
          iconSize: 20,
          items: BookViewType.values.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(type.icon, size: 20),
                  const SizedBox(width: 8),
                  Text(type.label),
                ],
              ),
            );
          }).toList(),
          onChanged: (type) {
            if (type != null) {
              setState(() => _viewType = type);
            }
          },
        ),
      ),
    );
  }

  Widget _buildBooksList(List<Book> books, dynamic user) {
    switch (_viewType) {
      case BookViewType.desktop:
        return DesktopBooksGrid(
          books: books,
          user: user,
          onDeleteBook: _showDeleteConfirmationDialog,
        );
      case BookViewType.mobile:
        return MobileBooksGrid(
          books: books,
          user: user,
          onDeleteBook: _showDeleteConfirmationDialog,
        );
      case BookViewType.table:
        return TableBooksView(
          books: books,
          user: user,
          onDeleteBook: _showDeleteConfirmationDialog,
        );
    }
  }

  void _showDeleteConfirmationDialog(BuildContext context, Book book) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Book'),
        content: const Text('Are you sure you want to delete this book? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<BooksBloc>().add(DeleteBook(book.id!));
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                const SnackBar(content: Text('Book deletion in progress...')),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}