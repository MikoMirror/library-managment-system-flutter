import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/book.dart';
import '../widgets/book_image_widget.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/book_reservation_dialog.dart';
import 'package:intl/intl.dart';
import '../widgets/book_details_card.dart';
import '../widgets/book_description_card.dart';

class BookInfoScreen extends StatelessWidget {
  final Book book;

  const BookInfoScreen({
    super.key,
    required this.book,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is! AuthSuccess) {
          return const Center(child: CircularProgressIndicator());
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Book Details'),
            actions: [
              if (state.user.role == 'admin')
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    // TODO: Implement edit functionality
                  },
                ),
            ],
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 900) {
                return _buildDesktopLayout(context, state);
              }
              return _buildMobileLayout(context, state);
            },
          ),
        );
      },
    );
  }

  Widget _buildDesktopLayout(BuildContext context, AuthSuccess state) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left column with image and reserve button
              SizedBox(
                width: 350,
                child: Column(
                  children: [
                    _buildBookImage(),
                    const SizedBox(height: 24),
                    _buildReserveButton(context, state),
                  ],
                ),
              ),
              const SizedBox(width: 32),
              // Right column with details
              Expanded(
                child: Card(
                  elevation: 2,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildBookHeader(context),
                        const SizedBox(height: 32),
                        BookDetailsCard(book: book),
                        const SizedBox(height: 32),
                        BookDescriptionCard(description: book.description),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, AuthSuccess state) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: Theme.of(context).colorScheme.surface,
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                _buildBookImage(),
                const SizedBox(height: 24),
                _buildBookHeader(context),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BookDetailsCard(book: book),
                const SizedBox(height: 16),
                BookDescriptionCard(description: book.description),
                const SizedBox(height: 24),
                _buildReserveButton(context, state),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookImage() {
    return Hero(
      tag: 'book-${book.id}',
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: BookImageWidget(
            book: book,
            isDetailView: true,
          ),
        ),
      ),
    );
  }

  Widget _buildBookHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          book.title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'by ${book.author}',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildReserveButton(BuildContext context, AuthSuccess state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Available Copies: ${book.booksQuantity}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              onPressed: book.booksQuantity > 0
                  ? () {
                      showDialog(
                        context: context,
                        builder: (context) => BookReservationDialog(
                          bookId: book.id!,
                          isAdmin: state.user.role == 'admin',
                          userId: state.user.userId,
                          booksQuantity: book.booksQuantity,
                        ),
                      );
                    }
                  : null,
              icon: const Icon(Icons.book),
              label: Text(
                book.booksQuantity > 0 ? 'Reserve Book' : 'Not Available',
              ),
            ),
          ],
        ),
      ),
    );
  }
} 