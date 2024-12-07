import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/bloc/auth/auth_bloc.dart';
import '../../books/models/book.dart';
import '../../books/widgets/book card/book_card.dart';
import '../../../core/services/database/firestore_service.dart';
import '../../books/screens/book_info_screen.dart';
import '../../books/widgets/delete_book_dialog.dart';
import '../../books/cubit/view/view_cubit.dart';
import '../../books/widgets/view_switcher.dart';
import '../../books/cubit/view/view_state.dart';
import '../../books/enums/book_view_type.dart';
import '../../books/widgets/book card/desktop_books_grid.dart';
import '../../books/widgets/book card/mobile_books_grid.dart';
import '../../books/widgets/book card/table_books_view.dart';
import '../../../features/users/models/user_model.dart';
import '../repositories/favorites_repository.dart';

class FavoritesScreen extends StatelessWidget {
  static final _firestore = FirebaseFirestore.instance;
  
  FavoritesScreen({super.key}) : _favoritesRepository = FavoritesRepository();
  
  final FavoritesRepository _favoritesRepository;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is! AuthSuccess) {
          return const Center(child: CircularProgressIndicator());
        }

        return FutureBuilder<DocumentSnapshot>(
          future: _firestore.collection('users').doc(state.user.uid).get(),
          builder: (context, userSnapshot) {
            if (!userSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final userData = userSnapshot.data!.data() as Map<String, dynamic>;
            final userModel = UserModel.fromMap(userData);

            return Scaffold(
              appBar: AppBar(
                title: const Text('My Favorites'),
                actions: [
                  if (!isMobile) const ViewSwitcher(),
                ],
              ),
              body: StreamBuilder<List<String>>(
                stream: _favoritesRepository.getUserFavoriteIds(state.user.uid),
                builder: (context, favoritesSnapshot) {
                  if (favoritesSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!favoritesSnapshot.hasData || favoritesSnapshot.data!.isEmpty) {
                    return const Center(
                      child: Text('No favorite books yet'),
                    );
                  }

                  return StreamBuilder<List<QueryDocumentSnapshot>>(
                    stream: _favoritesRepository.getFavoriteBooks(favoritesSnapshot.data!),
                    builder: (context, booksSnapshot) {
                      if (!booksSnapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final books = booksSnapshot.data!
                          .map((doc) => Book.fromMap(
                                doc.data() as Map<String, dynamic>,
                                doc.id,
                              ))
                          .toList();

                      return BlocBuilder<ViewCubit, ViewState>(
                        builder: (context, viewState) {
                          if (viewState is! ViewLoaded) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          switch (viewState.viewType) {
                            case BookViewType.desktop:
                              return DesktopBooksGrid(
                                books: books,
                                user: userModel,
                                onDeleteBook: _showDeleteBookDialog,
                              );
                            case BookViewType.mobile:
                              return MobileBooksGrid(
                                books: books,
                                user: userModel,
                                onDeleteBook: _showDeleteBookDialog,
                              );
                            case BookViewType.table:
                              return TableBooksView(
                                books: books,
                                user: userModel,
                                onDeleteBook: _showDeleteBookDialog,
                              );
                          }
                        },
                      );
                    },
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  void _showDeleteBookDialog(BuildContext context, Book book) {
    showDialog(
      context: context,
      builder: (BuildContext context) => DeleteBookDialog(book: book),
    );
  }
} 