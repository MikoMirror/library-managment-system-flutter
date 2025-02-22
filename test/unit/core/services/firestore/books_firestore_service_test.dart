import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:library_management_system/core/services/firestore/books_firestore_service.dart';
import 'package:library_management_system/features/books/models/book.dart';
import 'package:library_management_system/features/books/enums/sort_type.dart';
import 'package:library_management_system/features/dashboard/models/borrowing_trend_point.dart';
import 'package:library_management_system/features/reservation/models/reservation.dart';
import 'books_firestore_service_test.mocks.dart';

@GenerateMocks([
  FirebaseFirestore,
], customMocks: [
  MockSpec<CollectionReference<Map<String, dynamic>>>(as: #MockBookCollection),
  MockSpec<DocumentReference<Map<String, dynamic>>>(as: #MockBookDocument),
  MockSpec<Query<Map<String, dynamic>>>(as: #MockBookQuery),
  MockSpec<QuerySnapshot<Map<String, dynamic>>>(as: #MockBookQuerySnapshot),
  MockSpec<DocumentSnapshot<Map<String, dynamic>>>(as: #MockBookDocumentSnapshot),
  MockSpec<WriteBatch>(
    as: #MockBookWriteBatch,
    onMissingStub: OnMissingStub.returnDefault,
  ),
])
void main() {
  late BooksFirestoreService service;
  late MockFirebaseFirestore mockFirestore;
  late MockBookCollection mockCollection;
  late MockBookDocument mockDocument;
  late MockBookQuery mockQuery;
  late MockBookQuerySnapshot mockQuerySnapshot;
  late MockBookDocumentSnapshot mockDocSnapshot;
  late MockBookWriteBatch mockWriteBatch;

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockCollection = MockBookCollection();
    mockDocument = MockBookDocument();
    mockQuery = MockBookQuery();
    mockQuerySnapshot = MockBookQuerySnapshot();
    mockDocSnapshot = MockBookDocumentSnapshot();
    mockWriteBatch = MockBookWriteBatch();
    
    service = BooksFirestoreService.withFirestore(mockFirestore);

    // Common mock setups
    when(mockFirestore.collection(any)).thenReturn(mockCollection);
    when(mockCollection.doc(any)).thenReturn(mockDocument);
    when(mockFirestore.batch()).thenReturn(mockWriteBatch);
  });

  group('BooksFirestoreService', () {
    group('Basic Operations', () {
      test('getCollection returns correct collection reference', () {
        // Act
        final result = service.getCollection(BooksFirestoreService.collectionPath);
        
        // Assert
        verify(mockFirestore.collection(BooksFirestoreService.collectionPath)).called(1);
        expect(result, equals(mockCollection));
      });

      test('getDocumentStream returns correct document stream', () {
        // Arrange
        const testBookId = 'test-book-id';
        when(mockDocument.snapshots())
            .thenAnswer((_) => Stream.value(mockDocSnapshot));

        // Act
        final result = service.getDocumentStream(testBookId);

        // Assert
        verify(mockFirestore.collection(BooksFirestoreService.collectionPath)).called(1);
        verify(mockCollection.doc(testBookId)).called(1);
        expect(result, isA<Stream<DocumentSnapshot<Map<String, dynamic>>>>());
      });
    });

    group('Book Operations', () {
      test('addBook adds book with server timestamp', () async {
        // Arrange
        final testBook = Book(
          id: '1',
          title: 'Test Book',
          author: 'Test Author',
          isbn: '1234567890',
          description: 'Test Description',
          categories: ['Test'],
          pageCount: 100,
          publishedDate: Timestamp.now(),
          language: 'en',
          booksQuantity: 1,
        );
        when(mockCollection.add(any)).thenAnswer((_) => Future.value(mockDocument));

        // Act
        await service.addBook(testBook);

        // Assert
        verify(mockFirestore.collection(BooksFirestoreService.collectionPath)).called(1);
        verify(mockCollection.add(any)).called(1);
      });

      test('updateBook updates book data', () async {
        // Arrange
        final testBook = Book(
          id: '1',
          title: 'Updated Book',
          author: 'Updated Author',
          isbn: '1234567890',
          description: 'Updated Description',
          categories: ['Test'],
          pageCount: 100,
          publishedDate: Timestamp.now(),
          language: 'en',
          booksQuantity: 2,
        );
        when(mockDocument.update(any)).thenAnswer((_) => Future.value());

        // Act
        await service.updateBook(testBook);

        // Assert
        verify(mockFirestore.collection(BooksFirestoreService.collectionPath)).called(1);
        verify(mockCollection.doc(testBook.id)).called(1);
        verify(mockDocument.update(any)).called(1);
      });
    });

    group('Statistics and Trends', () {
      test('getBookStats returns correct statistics', () async {
        // Arrange
        final mockReservationsCollection = MockBookCollection();
        when(mockFirestore.collection('books_reservation'))
            .thenReturn(mockReservationsCollection);
        when(mockReservationsCollection.where(any, whereIn: anyNamed('whereIn')))
            .thenReturn(mockQuery);
        when(mockQuery.get())
            .thenAnswer((_) => Future.value(mockQuerySnapshot));
        when(mockCollection.get())
            .thenAnswer((_) => Future.value(mockQuerySnapshot));
        when(mockQuerySnapshot.docs).thenReturn([]);

        // Act
        final result = await service.getBookStats();

        // Assert
        expect(result, isA<Map<String, dynamic>>());
        expect(result.keys, containsAll([
          'uniqueBooks',
          'totalBooks',
          'reservedBooks',
          'borrowedBooks',
          'overdueBooks',
        ]));
      });

      test('getBorrowingTrends returns correct trend data', () async {
        // Arrange
        final startDate = DateTime(2024, 1, 1);
        final endDate = DateTime(2024, 1, 31);
        
        when(mockFirestore.collection('books_reservation'))
            .thenReturn(mockCollection);
        when(mockCollection.where('status', whereIn: ['borrowed', 'returned', 'overdue']))
            .thenReturn(mockQuery);
        when(mockQuery.where('borrowedDate', 
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate)))
            .thenReturn(mockQuery);
        when(mockQuery.where('borrowedDate', 
            isLessThanOrEqualTo: Timestamp.fromDate(endDate)))
            .thenReturn(mockQuery);
        when(mockQuery.get())
            .thenAnswer((_) => Future.value(mockQuerySnapshot));
        when(mockQuerySnapshot.docs).thenReturn([]);

        // Act
        final result = await service.getBorrowingTrends(
          startDate: startDate,
          endDate: endDate,
          status: 'borrowed',
        );

        // Assert
        expect(result, isA<List<BorrowingTrendPoint>>());
      });
    });

    group('Sorting and Filtering', () {
      test('getBooksStream with rating sort', () {
        // Arrange
        when(mockCollection.orderBy(any, descending: anyNamed('descending')))
            .thenReturn(mockQuery);
        when(mockQuery.snapshots())
            .thenAnswer((_) => Stream.value(mockQuerySnapshot));

        // Act
        final result = service.getBooksStream(sortType: SortType.rating);

        // Assert
        verify(mockCollection.orderBy('averageRating', descending: true)).called(1);
        expect(result, isA<Stream<QuerySnapshot<Map<String, dynamic>>>>());
      });

      test('getBooksStream with date sort', () {
        // Arrange
        when(mockCollection.orderBy(any, descending: anyNamed('descending')))
            .thenReturn(mockQuery);
        when(mockQuery.snapshots())
            .thenAnswer((_) => Stream.value(mockQuerySnapshot));

        // Act
        final result = service.getBooksStream(sortType: SortType.date);

        // Assert
        verify(mockCollection.orderBy('publishedDate', descending: true)).called(1);
        expect(result, isA<Stream<QuerySnapshot<Map<String, dynamic>>>>());
      });
    });
  });
} 