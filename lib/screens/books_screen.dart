import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/book.dart';
import '../widgets/add_book_dialog.dart';
import '../widgets/book_card.dart';
import 'dart:async';
import '../screens/book_info_screen.dart';
import '../widgets/custom_app_bar.dart';
import '../services/firestore_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';

class BooksScreen extends StatefulWidget {
  const BooksScreen({super.key});

  @override
  State<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String _searchQuery = '';
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;
  bool _isTableView = false;

  void _handleSearch(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = query.toLowerCase();
      });
    });
  }

  void _toggleViewMode() {
    setState(() {
      _isTableView = !_isTableView;
    });
  }

  Future<void> _toggleFavorite(BuildContext context, Book book) async {
    final state = context.read<AuthBloc>().state;
    if (state is AuthSuccess) {
      try {
        await _firestoreService.toggleFavorite(state.user.userId, book.id!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Updated favorites'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating favorites: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is! AuthSuccess) {
          return const Center(child: CircularProgressIndicator());
        }

        final isAdmin = state.user.role == 'admin';

        return Scaffold(
          appBar: CustomAppBar(
            title: const Text('Books'),
            actions: [
              IconButton(
                icon: Icon(_isTableView ? Icons.grid_view : Icons.table_rows),
                onPressed: _toggleViewMode,
                tooltip: _isTableView ? 'Switch to Cards' : 'Switch to Table',
              ),
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  // TODO: Implement search
                },
              ),
            ],
          ),
          body: _buildBookList(isAdmin, state.user.userId),
          floatingActionButton: isAdmin
              ? FloatingActionButton(
                  onPressed: () => _showAddBookDialog(context),
                  child: const Icon(Icons.add),
                )
              : null,
        );
      },
    );
  }

  Widget _buildBookList(bool isAdmin, String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('books').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'No books available.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          );
        }

        var books = snapshot.data!.docs
            .map((doc) => Book.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .where((book) =>
                book.title.toLowerCase().contains(_searchQuery) ||
                book.author.toLowerCase().contains(_searchQuery))
            .toList();

        return _isTableView
            ? _buildTableView(books, isAdmin, userId)
            : _buildCardsView(books, isAdmin, userId);
      },
    );
  }

  Widget _buildTableView(List<Book> books, bool isAdmin, String userId) {
    return SingleChildScrollView(
      controller: _scrollController,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Table Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: const Row(
                children: [
                  SizedBox(width: 60), // Cover space
                  SizedBox(width: 16),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Title',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Author',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Pages',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(width: 100), // Actions space
                ],
              ),
            ),
            // Table Rows
            ...books.map((book) => Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: InkWell(
                    onTap: () => _navigateToBookDetail(context, book),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          // Book Cover
                          SizedBox(
                            width: 60,
                            height: 80,
                            child: book.externalImageUrl != null
                                ? Image.network(
                                    book.externalImageUrl!,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.book),
                                  ),
                          ),
                          const SizedBox(width: 16),
                          // Title
                          Expanded(
                            flex: 3,
                            child: Text(
                              book.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Author
                          Expanded(
                            flex: 2,
                            child: Text(
                              book.author,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Pages
                          Expanded(
                            child: Text(
                              book.pageCount.toString(),
                            ),
                          ),
                          // Actions
                          SizedBox(
                            width: 100,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (isAdmin) ...[
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () {
                                      // TODO: Implement edit
                                    },
                                    iconSize: 20,
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () =>
                                        _showDeleteBookDialog(context, book),
                                    iconSize: 20,
                                  ),
                                ] else
                                  StreamBuilder<bool>(
                                    stream: _firestoreService.isBookFavorited(userId, book.id!),
                                    builder: (context, snapshot) {
                                      final isFavorite = snapshot.data ?? false;
                                      return IconButton(
                                        icon: Icon(
                                          isFavorite ? Icons.favorite : Icons.favorite_border,
                                          color: Colors.red,
                                        ),
                                        onPressed: () => _toggleFavorite(context, book),
                                        iconSize: 20,
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildCardsView(List<Book> books, bool isAdmin, String userId) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 1;
        if (constraints.maxWidth > 1600) {
          crossAxisCount = 3;
        } else if (constraints.maxWidth > 800) {
          crossAxisCount = 2;
        }

        return GridView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: (constraints.maxWidth / crossAxisCount) / 200,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: books.length,
          itemBuilder: (context, index) {
            final book = books[index];
            return BookCard(
              book: book,
              onTap: () => _navigateToBookDetail(context, book),
              onDelete: isAdmin 
                  ? () => _showDeleteBookDialog(context, book)
                  : null,
              onToggleFavorite: !isAdmin 
                  ? () => _toggleFavorite(context, book)
                  : null,
              userId: userId,
            );
          },
        );
      },
    );
  }

  void _showAddBookDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const AddBookDialog();
      },
    );
  }

  void _showDeleteBookDialog(BuildContext context, Book book) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Book'),
          content: Text('Are you sure you want to delete "${book.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await _firestoreService.deleteBook('books', book.id!);
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Book deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting book: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _navigateToBookDetail(BuildContext context, Book book) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookInfoScreen(book: book),
      ),
    );
  }
} 