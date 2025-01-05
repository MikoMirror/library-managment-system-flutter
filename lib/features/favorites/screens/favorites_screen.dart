import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/bloc/auth/auth_bloc.dart';
import '../../books/models/book.dart';
import '../../../core/widgets/app_bar.dart';
import '../../books/enums/book_view_type.dart';
import '../../books/widgets/book card/desktop_books_grid.dart';
import '../../books/widgets/book card/mobile_books_grid.dart';
import '../../books/widgets/book card/table_books_view.dart';
import '../../../features/users/models/user_model.dart';
import '../repositories/favorites_repository.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> with SingleTickerProviderStateMixin {
  final _firestore = FirebaseFirestore.instance;
  final _favoritesRepository = FavoritesRepository();
  final _searchController = TextEditingController();
  BookViewType _viewType = BookViewType.desktop;
  UserModel? _cachedUserModel;
  final Map<String, Book> _bookCache = {};
  String _searchQuery = '';
  bool _isSearchVisible = false;

  // Add animation controller
  late final AnimationController _animationController;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _favoritesRepository.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearchVisible = !_isSearchVisible;
      if (_isSearchVisible) {
        _animationController.forward();
      } else {
        _animationController.reverse();
        _searchController.clear();
        setState(() {
          _searchQuery = '';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    
    return Scaffold(
      appBar: UnifiedAppBar(
        title: const Text(
          'Favorites',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        searchHint: 'Search favorites...',
        onSearch: (query) {
          setState(() {
            _searchQuery = query;
          });
        },
        actions: [
          if (isDesktop)
            IconButton(
              icon: Icon(_viewType.icon),
              onPressed: () {
                setState(() {
                  _viewType = BookViewType.values[
                    (_viewType.index + 1) % BookViewType.values.length
                  ];
                });
              },
            ),
        ],
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is! AuthSuccess) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_cachedUserModel != null) {
            return _buildFavoritesList(state.user.uid, _cachedUserModel!);
          }

          return FutureBuilder<DocumentSnapshot>(
            future: _firestore.collection('users').doc(state.user.uid).get(),
            builder: (context, userSnapshot) {
              if (!userSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final userData = userSnapshot.data!.data() as Map<String, dynamic>;
              _cachedUserModel = UserModel.fromMap(userData);

              return _buildFavoritesList(state.user.uid, _cachedUserModel!);
            },
          );
        },
      ),
    );
  }

  Widget _buildFavoritesList(String userId, UserModel userModel) {
    return StreamBuilder<List<Book>>(
      stream: _favoritesRepository.getFavoriteBooks(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && _bookCache.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final books = snapshot.data ?? [];
        
        // Update cache
        for (final book in books) {
          _bookCache[book.id!] = book;
        }

        final isMobile = MediaQuery.of(context).size.width < 600;

        if (_bookCache.isEmpty) {
          return const Center(
            child: Text(
              'No favorite books yet',
              style: TextStyle(fontSize: 18),
            ),
          );
        }

        final booksList = _bookCache.values
            .where((book) => 
                book.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                book.author.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

        if (isMobile) {
          return MobileBooksGrid(
            books: booksList,
            userId: userId,
            isAdmin: userModel.role == 'admin',
            onDeleteBook: (_, __) {},
          );
        }

        return _buildBooksList(booksList, userId, userModel.role == 'admin');
      },
    );
  }

  Widget _buildBooksList(List<Book> books, String userId, bool isAdmin) {
    switch (_viewType) {
      case BookViewType.desktop:
        return DesktopBooksGrid(
          books: books,
          userId: userId,
          isAdmin: isAdmin,
          onDeleteBook: (_, __) {}, // No delete functionality for favorites
        );
      case BookViewType.mobile:
        return MobileBooksGrid(
          books: books,
          userId: userId,
          isAdmin: isAdmin,
          onDeleteBook: (_, __) {}, // No delete functionality for favorites
        );
      case BookViewType.table:
        return TableBooksView(
          books: books,
          userId: userId,
          isAdmin: isAdmin,
          onDeleteBook: (_, __) {}, // No delete functionality for favorites
        );
    }
  }

  IconData get _viewTypeIcon {
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