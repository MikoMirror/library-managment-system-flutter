import 'package:flutter/material.dart';
import '../../models/book.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/book_card_bloc.dart';
import '../../repositories/books_repository.dart';
import '../../screens/book_details_screen.dart';
import '../../../../core/services/image/image_cache_service.dart';

class TableBooksView extends StatefulWidget {
  final List<Book> books;
  final bool isAdmin;
  final String? userId;
  final Function(BuildContext, Book)? onDeleteBook;

  const TableBooksView({
    super.key,
    required this.books,
    this.isAdmin = false,
    this.userId,
    this.onDeleteBook,
  });

  @override
  State<TableBooksView> createState() => _TableBooksViewState();
}

class _TableBooksViewState extends State<TableBooksView> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Theme(
        data: Theme.of(context).copyWith(
          dataTableTheme: const DataTableThemeData(
            dataRowMinHeight: 80,
            dataRowMaxHeight: 80,
            horizontalMargin: 24,
            columnSpacing: 24,
          ),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 800),
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Cover')),
              DataColumn(label: Text('Title')),
              DataColumn(label: Text('Author')),
              DataColumn(label: Text('Language')),
              DataColumn(label: Text('Rating')),
              DataColumn(label: Text('Actions')),
            ],
            rows: widget.books.map((book) => _buildBookRow(context, book)).toList(),
          ),
        ),
      ),
    );
  }

  DataRow _buildBookRow(BuildContext context, Book book) {
    return DataRow.byIndex(
      index: widget.books.indexOf(book),
      cells: [
        DataCell(
          SizedBox(
            width: 50,
            height: 70,
            child: ImageCacheService().buildCachedImage(
              imageUrl: book.externalImageUrl ?? 'placeholder_url',
              fit: BoxFit.cover,
              width: 50,
              height: 70,
            ),
          ),
        ),
        DataCell(
          Text(
            book.title,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BookDetailsScreen(bookId: book.id),
              ),
            );
          },
        ),
        DataCell(Text(book.author)),
        DataCell(Text(book.language.toUpperCase())),
        DataCell(Row(
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 16),
            const SizedBox(width: 4),
            Text(book.averageRating.toStringAsFixed(1)),
          ],
        )),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!widget.isAdmin && widget.userId != null)
                BlocProvider(
                  create: (context) {
                    final bloc = BookCardBloc(context.read<BooksRepository>());
                    // Defer Firestore operation
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (bloc.state is! FavoriteStatusLoaded) {
                        bloc.add(LoadFavoriteStatus(widget.userId!, book.id!));
                      }
                    });
                    return bloc;
                  },
                  child: BlocBuilder<BookCardBloc, BookCardState>(
                    builder: (context, state) {
                      bool isFavorite = state is FavoriteStatusLoaded ? state.isFavorite : false;
                      return IconButton(
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: Colors.red,
                        ),
                        onPressed: () => context.read<BookCardBloc>()
                            .add(ToggleFavorite(widget.userId!, book.id!)),
                      );
                    },
                  ),
                ),
              if (widget.isAdmin && widget.onDeleteBook != null)
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => widget.onDeleteBook?.call(context, book),
                  color: Colors.grey[800],
                ),
            ],
          ),
        ),
      ],
    );
  }
} 
