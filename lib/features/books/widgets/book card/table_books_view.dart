import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../../models/book.dart';
import 'book_card_mixin.dart';
import '../../../../core/services/database/firestore_service.dart';
import '../../../../features/users/models/user_model.dart';

class TableBooksView extends StatefulWidget {
  final List<Book> books;
  final dynamic user;
  final Function(BuildContext, Book) onDeleteBook;

  TableBooksView({
    super.key,
    required this.books,
    required this.user,
    required this.onDeleteBook,
  });

  @override
  State<TableBooksView> createState() => _TableBooksViewState();
}

class _TableBooksViewState extends State<TableBooksView> with BookCardMixin {
  String? get userId {
    if (widget.user is UserModel) {
      return (widget.user as UserModel).userId;
    }
    return widget.user.uid;
  }

  bool get isAdmin {
    if (widget.user is UserModel) {
      return (widget.user as UserModel).role == 'admin';
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          dataRowHeight: 100,
          columnSpacing: 24,
          columns: const [
            DataColumn(label: Text('Cover')),
            DataColumn(label: Text('Title')),
            DataColumn(label: Text('Author')),
            DataColumn(label: Text('Rating')),
            DataColumn(label: Text('Actions')),
          ],
          rows: widget.books.map((book) => _buildBookRow(context, book)).toList(),
        ),
      ),
    );
  }

  DataRow _buildBookRow(BuildContext context, Book book) {
    return DataRow(
      cells: [
        DataCell(
          SizedBox(
            width: 70,
            height: 90,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                book.coverUrl,
                fit: BoxFit.cover,
              ),
            ),
          ),
          onTap: () => handleBookTap(context, book),
        ),
        DataCell(
          Text(
            book.title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          onTap: () => handleBookTap(context, book),
        ),
        DataCell(
          Text(book.author),
          onTap: () => handleBookTap(context, book),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 16),
              const SizedBox(width: 4),
              Text(book.averageRating.toStringAsFixed(1)),
            ],
          ),
          onTap: () => handleBookTap(context, book),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isAdmin)
                StreamBuilder<bool>(
                  stream: FirestoreService().getFavoriteStatus(userId ?? '', book.id!),
                  builder: (context, snapshot) {
                    final isFavorite = snapshot.data ?? false;
                    return IconButton(
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: Colors.red,
                      ),
                      onPressed: () => handleFavoriteToggle(userId ?? '', book.id!),
                    );
                  },
                ),
              if (isAdmin)
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => widget.onDeleteBook(context, book),
                ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    // Clean up the mixin streams
    super.dispose();
  }
} 
