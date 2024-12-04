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
import 'book_form_screen.dart';
import '../widgets/delete_book_dialog.dart';

class BooksScreen extends StatefulWidget {
  const BooksScreen({super.key});

  @override
  State<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen> {
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

  @override
  Widget build(BuildContext context) {
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
      body: _buildBookList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddBookDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBookList() {
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
            ? _buildTableView(books)
            : _buildCardsView(books);
      },
    );
  }

  Widget _buildTableView(List<Book> books) {
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
                  padding: const EdgeInsets.all(8.0),
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
                            BlocBuilder<AuthBloc, AuthState>(
                              builder: (context, state) {
                                if (state is AuthSuccess) {
                                  if (state.user.role == 'admin') {
                                    // Admin sees edit and delete buttons
                                    return Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit),
                                          onPressed: () => _navigateToEditBook(context, book),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete),
                                          onPressed: () => _showDeleteBookDialog(context, book),
                                        ),
                                      ],
                                    );
                                  } else {
                                    // Library member sees favorite button
                                    return StreamBuilder<bool>(
                                      stream: FirestoreService().isBookFavorited(
                                        state.user.userId,
                                        book.id!,
                                      ),
                                      builder: (context, snapshot) {
                                        final isFavorited = snapshot.data ?? false;
                                        return IconButton(
                                          icon: Icon(
                                            isFavorited ? Icons.favorite : Icons.favorite_border,
                                            color: isFavorited ? Colors.red : null,
                                          ),
                                          onPressed: () async {
                                            await FirestoreService().toggleFavorite(
                                              state.user.userId,
                                              book.id!,
                                            );
                                          },
                                        );
                                      },
                                    );
                                  }
                                }
                                return const SizedBox.shrink();
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

  Widget _buildCardsView(List<Book> books) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 1;
        if (constraints.maxWidth > 1600) {
          crossAxisCount = 3;
        } else if (constraints.maxWidth > 800) {
          crossAxisCount = 2;
        }

        return BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is! AuthSuccess) {
              return const Center(child: CircularProgressIndicator());
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
                  onDelete: state.user.role == 'admin' 
                      ? () => _showDeleteBookDialog(context, book) 
                      : null,
                  isAdmin: state.user.role == 'admin',
                  userId: state.user.userId,
                  onFavoriteToggle: () async {
                    await FirestoreService().toggleFavorite(
                      state.user.userId,
                      book.id!,
                    );
                  },
                );
              },
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
      builder: (BuildContext context) => DeleteBookDialog(book: book),
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
    );
  }
} 