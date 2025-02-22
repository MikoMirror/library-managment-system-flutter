import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:library_management_system/core/services/firestore/books_firestore_service.dart';
import 'package:library_management_system/features/books/repositories/books_repository.dart';
import 'package:library_management_system/features/books/models/book.dart';
import 'books_repository_test.mocks.dart';

@GenerateMocks([BooksFirestoreService])
void main() {
  late BooksRepository repository;
  late MockBooksFirestoreService mockService;

  setUp(() {
    print('📝 Setting up test environment...');
    mockService = MockBooksFirestoreService();
    repository = BooksRepository(firestoreService: mockService);
  });

  tearDown(() {
    print('🧹 Cleaning up test environment...');
  });

  group('BooksRepository', () {
    final mockBook = Book(
      id: '1',
      title: 'Test Book',
      author: 'Test Author',
      isbn: '9780123456789',
      description: 'Test Description',
      categories: ['Test'],
      pageCount: 100,
      publishedDate: Timestamp.now(),
      language: 'en',
      booksQuantity: 1,
    );

    test('addBook delegates to service', () async {
      print('📚 Testing book addition...');
      // Arrange
      when(mockService.addDocument(any, any))
          .thenAnswer((_) => Future.value());

      // Act
      await repository.addBook(mockBook);

      // Assert
      verify(mockService.addDocument(
        BooksRepository.collectionPath,
        any,
      )).called(1);
      print('✅ Book addition test passed');
    });

    test('getAllBooks delegates to service', () {
      print('📋 Testing getAllBooks...');
      // Arrange
      final List<Book> mockBooks = [mockBook];
      when(mockService.getCollectionStream<Book>(
        collection: anyNamed('collection'),
        fromMap: anyNamed('fromMap'),
      )).thenAnswer((_) => Stream.value(mockBooks));

      // Act & Assert
      expect(repository.getAllBooks(), emits(mockBooks));
      print('✅ getAllBooks test passed');
    });

    test('searchBooks filters books correctly', () {
      print('🔍 Testing book search...');
      // Arrange
      final List<Book> mockBooks = [mockBook];
      when(mockService.getCollectionStream<Book>(
        collection: anyNamed('collection'),
        fromMap: anyNamed('fromMap'),
      )).thenAnswer((_) => Stream.value(mockBooks));

      // Act & Assert
      expect(repository.searchBooks('Test'), emits([mockBook]));
      expect(repository.searchBooks('NonExistent'), emits([]));
      print('✅ Book search test passed');
    });

    test('deleteBook delegates to service', () async {
      print('🗑️ Testing book deletion...');
      // Arrange
      when(mockService.deleteDocument(any, any))
          .thenAnswer((_) => Future.value());

      // Act
      await repository.deleteBook('1');

      // Assert
      verify(mockService.deleteDocument(
        BooksRepository.collectionPath,
        '1',
      )).called(1);
      print('✅ Book deletion test passed');
    });

    test('updateBookQuantity delegates to service', () async {
      print('📦 Testing book quantity update...');
      // Arrange
      when(mockService.updateDocument(any, any, any))
          .thenAnswer((_) => Future.value());

      // Act
      await repository.updateBookQuantity('1', 5);

      // Assert
      verify(mockService.updateDocument(
        BooksRepository.collectionPath,
        '1',
        {'booksQuantity': 5},
      )).called(1);
      print('✅ Book quantity update test passed');
    });

    test('rateBook delegates to service', () async {
      print('⭐ Testing book rating...');
      // Arrange
      when(mockService.updateDocument(any, any, any))
          .thenAnswer((_) => Future.value());

      // Act
      await repository.rateBook('1', 'user1', 4.5);

      // Assert
      verify(mockService.updateDocument(
        BooksRepository.collectionPath,
        '1',
        {'ratings.user1': 4.5},
      )).called(1);
      print('✅ Book rating test passed');
    });
  });
} 