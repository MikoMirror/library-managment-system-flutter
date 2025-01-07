import 'package:cloud_firestore/cloud_firestore.dart';
import 'base_firestore_service.dart';
import '../../../features/books/models/book.dart';
import '../../../features/dashboard/models/borrowing_trend_point.dart';
import '../../../features/reservation/models/reservation.dart';
import 'package:logger/logger.dart';
import '../../../features/books/enums/sort_type.dart';

class BooksFirestoreService extends BaseFirestoreService {
  static const String collectionPath = 'books';
  final _favoriteCache = <String, Stream<bool>>{};
  final _logger = Logger();

  CollectionReference<Map<String, dynamic>> getCollection(String path) {
    return firestore.collection(path);
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> getDocumentStream(String bookId) {
    return firestore
        .collection(collectionPath)
        .doc(bookId)
        .snapshots();
  }

  Future<void> addBook(Book book) async {
    final bookData = book.toMap();
    bookData['createdAt'] = FieldValue.serverTimestamp();
    await addDocument(collectionPath, bookData);
  }

  Stream<List<Book>> getAllBooks() {
    return getCollectionStream(
      collection: collectionPath,
      fromMap: (data, id) => Book.fromMap(data, id),
    );
  }

  Future<void> updateBookQuantity(String bookId, int quantity) async {
    await updateDocument(collectionPath, bookId, {'booksQuantity': quantity});
  }

  Future<void> rateBook(String bookId, String userId, double rating) async {
    await updateDocument(collectionPath, bookId, {
      'ratings.$userId': rating,
    });
  }

  Stream<bool> getFavoriteStatus(String userId, String bookId) {
    final cacheKey = '$userId-$bookId';
    
    if (_favoriteCache.containsKey(cacheKey)) {
      return _favoriteCache[cacheKey]!;
    }

    final stream = firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(bookId)
        .snapshots()
        .map((snapshot) => snapshot.exists)
        .distinct();

    _favoriteCache[cacheKey] = stream;
    return stream;
  }

  Future<void> updateBook(Book book) async {
    if (book.id == null) {
      throw Exception('Book ID cannot be null when updating');
    }
    
    final bookData = book.toMap();
    await updateDocument(collectionPath, book.id!, bookData);
  }

  @override
  DocumentReference<Map<String, dynamic>> getDocumentReference(String collection, String documentId) {
    return firestore.collection(collection).doc(documentId);
  }

  Future<Map<String, int>> getDashboardStats() async {
    final booksSnapshot = await getCollection(collectionPath).get();
    final reservationsSnapshot = await firestore.collection('books_reservation').get();

    int uniqueBooks = booksSnapshot.size;
    int totalBooks = 0;
    int reservedBooks = 0;
    int borrowedBooks = 0;
    int overdueBooks = 0;

    for (var doc in booksSnapshot.docs) {
      totalBooks += (doc.data()['booksQuantity'] as int?) ?? 0;
    }
    final now = DateTime.now();
    for (var doc in reservationsSnapshot.docs) {
      final data = doc.data();
      final status = data['status'] as String;
      final quantity = data['quantity'] as int;
      final dueDate = (data['dueDate'] as Timestamp).toDate();

      switch (status) {
        case 'reserved':
          reservedBooks += quantity;
          break;
        case 'borrowed':
          borrowedBooks += quantity;
          if (dueDate.isBefore(now)) {
            overdueBooks += quantity;
          }
          break;
      }
    }

    return {
      'uniqueBooks': uniqueBooks,
      'totalBooks': totalBooks,
      'reservedBooks': reservedBooks,
      'borrowedBooks': borrowedBooks,
      'overdueBooks': overdueBooks,
    };
  }

  Future<List<BorrowingTrendPoint>> getBorrowingTrends({
    required DateTime startDate,
    required DateTime endDate,
    required String status,
  }) async {
    try {
      final querySnapshot = await firestore
          .collection('books_reservation')
          .where('status', whereIn: status == 'borrowed' 
              ? ['borrowed', 'returned', 'overdue'] 
              : [status])
          .where('borrowedDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('borrowedDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      final trendsMap = <DateTime, int>{};
      final sortedDocs = querySnapshot.docs
        ..sort((a, b) => (a.data()['borrowedDate'] as Timestamp)
            .compareTo(b.data()['borrowedDate'] as Timestamp));

      int runningTotal = 0;
      
      for (var doc in sortedDocs) {
        final data = doc.data();
        final date = (data['borrowedDate'] as Timestamp).toDate();
        final dateOnly = DateTime(date.year, date.month, date.day);
        final quantity = data['quantity'] as int;
        
        if (status == 'borrowed') {
          runningTotal += quantity;
          trendsMap[dateOnly] = runningTotal;
        } else {
          trendsMap[dateOnly] = (trendsMap[dateOnly] ?? 0) + quantity;
        }
      }

      return trendsMap.entries
          .map((entry) => BorrowingTrendPoint(
                timestamp: entry.key,
                count: entry.value,
              ))
          .toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    } catch (e) {
      _logger.e('Error getting borrowing trends: $e');
      return [];
    }
  }

  Future<List<Reservation>> getReservationsForReport(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final startTimestamp = Timestamp.fromDate(startDate);
    final endTimestamp = Timestamp.fromDate(endDate);

    final querySnapshot = await firestore
        .collection('books_reservation')
        .where('borrowedDate', isGreaterThanOrEqualTo: startTimestamp)
        .where('borrowedDate', isLessThanOrEqualTo: endTimestamp)
        .get();

    return querySnapshot.docs
        .map((doc) => Reservation.fromMap(doc.data(), doc.id))
        .toList();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getBooksStream({SortType? sortType}) {
    Query<Map<String, dynamic>> query = firestore.collection(collectionPath);
    
    switch (sortType) {
      case SortType.rating:
        query = query.orderBy('averageRating', descending: true);
        break;
      case SortType.date:
        query = query.orderBy('publishedDate', descending: true);
        break;
      case SortType.createdAt:
        query = query
            .orderBy('createdAt', descending: true)
            .orderBy('title');
        break;
      case SortType.none:
      default:
        break;
    }
    
    return query.snapshots();
  }
} 