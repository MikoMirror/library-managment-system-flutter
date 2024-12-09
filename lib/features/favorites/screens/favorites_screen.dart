import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/bloc/auth/auth_bloc.dart';
import '../../books/models/book.dart';
import '../../../core/widgets/custom_app_bar.dart';
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

class _FavoritesScreenState extends State<FavoritesScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _favoritesRepository = FavoritesRepository();
  BookViewType _viewType = BookViewType.desktop;
  UserModel? _cachedUserModel;
  Map<String, Book> _bookCache = {};

  @override
  void dispose() {
    _favoritesRepository.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    return Scaffold(
      appBar: CustomAppBar(
        title: const Text('Favorites'),
        actions: [
          if (!isMobile) _buildViewSwitcher(context),
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

        final booksList = _bookCache.values.toList();

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

  Widget _buildViewSwitcher(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<BookViewType>(
          value: _viewType,
          icon: const Icon(Icons.arrow_drop_down),
          iconSize: 20,
          elevation: 4,
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
} 