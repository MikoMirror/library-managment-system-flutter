import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../bloc/auth_bloc.dart';
import '../models/book.dart';
import '../widgets/book_card.dart';
import '../services/firestore_service.dart';
import 'book_info_screen.dart';
import '../widgets/delete_book_dialog.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is! AuthSuccess) {
          return const Center(child: CircularProgressIndicator());
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('My Favorites'),
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: FirestoreService().getUserFavorites(state.user.userId),
            builder: (context, favoritesSnapshot) {
              if (favoritesSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!favoritesSnapshot.hasData || favoritesSnapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text('No favorite books yet'),
                );
              }

              final favoriteIds = favoritesSnapshot.data!.docs
                  .map((doc) => doc.id)
                  .toList();

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('books')
                    .where(FieldPath.documentId, whereIn: favoriteIds)
                    .snapshots(),
                builder: (context, booksSnapshot) {
                  if (!booksSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final books = booksSnapshot.data!.docs
                      .map((doc) => Book.fromMap(doc.data() as Map<String, dynamic>, doc.id))
                      .toList();

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      int crossAxisCount = 1;
                      if (constraints.maxWidth > 1600) {
                        crossAxisCount = 3;
                      } else if (constraints.maxWidth > 800) {
                        crossAxisCount = 2;
                      }

                      return GridView.builder(
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
                          return BlocBuilder<AuthBloc, AuthState>(
                            builder: (context, state) {
                              if (state is! AuthSuccess) {
                                return const SizedBox.shrink();
                              }

                              return BookCard(
                                book: book,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => BookInfoScreen(book: book),
                                  ),
                                ),
                                isAdmin: state.user.role == 'admin',
                                userId: state.user.userId,
                                onFavoriteToggle: () async {
                                  await FirestoreService().toggleFavorite(
                                    state.user.userId,
                                    book.id!,
                                  );
                                },
                                onDelete: state.user.role == 'admin' 
                                    ? () => _showDeleteBookDialog(context, book)
                                    : null,
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          ),
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