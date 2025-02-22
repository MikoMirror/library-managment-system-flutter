import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:library_management_system/features/books/bloc/books_bloc.dart';
import 'package:library_management_system/features/books/bloc/books_event.dart';
import 'package:library_management_system/features/books/bloc/books_state.dart';
import 'package:library_management_system/features/books/repositories/books_repository.dart';
import 'package:library_management_system/features/books/models/book.dart';
import 'books_bloc_test.mocks.dart';

@GenerateMocks([BooksRepository])
void main() {
  late BooksBloc booksBloc;
  late MockBooksRepository mockRepository;

  setUp(() {
    print('📝 Setting up test environment...');
    mockRepository = MockBooksRepository();
    booksBloc = BooksBloc(repository: mockRepository);
  });

  tearDown(() {
    print('🧹 Cleaning up test environment...');
    booksBloc.close();
  });

  test('initial state is BooksInitial', () {
    print('🔍 Testing initial state...');
    expect(booksBloc.state, isA<BooksInitial>());
    print('✅ Initial state test passed');
  });

  group('DeleteBook', () {
    final mockBooks = [
      Book(
        id: '1',
        title: 'Test Book 1',
        author: 'Author 1',
        isbn: '123456789',
        description: 'Description 1',
        categories: ['Fiction'],
        pageCount: 200,
        publishedDate: Timestamp.now(),
        language: 'en',
        booksQuantity: 1,
      ),
    ];

    blocTest<BooksBloc, BooksState>(
      'emits correct states when deletion is successful',
      setUp: () => print('🗑️ Testing successful book deletion...'),
      seed: () => BooksLoaded(books: mockBooks),
      build: () {
        when(mockRepository.deleteBook(any))
            .thenAnswer((_) => Future.value());
        when(mockRepository.getAllBooks())
            .thenAnswer((_) => Stream.value([]));
        return booksBloc;
      },
      act: (bloc) => bloc.add(const DeleteBook('1')),
      expect: () => [
        isA<BooksLoaded>().having((state) => state.books, 'books', []),
      ],
      verify: (_) => print('✅ Successful deletion test passed'),
    );

    blocTest<BooksBloc, BooksState>(
      'emits error state when deletion fails',
      setUp: () => print('❌ Testing failed book deletion...'),
      seed: () => BooksLoaded(books: mockBooks),
      build: () {
        when(mockRepository.deleteBook(any))
            .thenThrow('Error deleting book');
        return booksBloc;
      },
      act: (bloc) => bloc.add(const DeleteBook('1')),
      expect: () => [
        isA<BooksError>()
            .having((state) => state.message, 'error', 'Error deleting book'),
      ],
      verify: (_) => print('✅ Failed deletion error handling test passed'),
    );
  });

  group('LoadBooksEvent', () {
    final mockBooks = [
      Book(
        id: '1',
        title: 'Test Book 1',
        author: 'Author 1',
        isbn: '123456789',
        description: 'Description 1',
        categories: ['Fiction'],
        pageCount: 200,
        publishedDate: Timestamp.now(),
        language: 'en',
        booksQuantity: 1,
      ),
    ];

    blocTest<BooksBloc, BooksState>(
      'emits [BooksLoading, BooksLoaded] when successful',
      setUp: () => print('📚 Testing successful books loading...'),
      build: () {
        when(mockRepository.getAllBooks())
            .thenAnswer((_) => Stream.value(mockBooks));
        return booksBloc;
      },
      act: (bloc) => bloc.add(const LoadBooksEvent()),
      expect: () => [
        isA<BooksLoading>(),
        isA<BooksLoaded>()
            .having((state) => state.books, 'books', mockBooks),
      ],
      verify: (_) => print('✅ Successful loading test passed'),
    );

    blocTest<BooksBloc, BooksState>(
      'emits [BooksLoading, BooksError] when loading fails',
      setUp: () => print('❌ Testing failed books loading...'),
      build: () {
        when(mockRepository.getAllBooks())
            .thenAnswer((_) => Stream.error('Error loading books'));
        return booksBloc;
      },
      act: (bloc) => bloc.add(const LoadBooksEvent()),
      expect: () => [
        isA<BooksLoading>(),
        isA<BooksError>()
            .having((state) => state.message, 'error', 'Error loading books'),
      ],
      verify: (_) => print('✅ Failed loading error handling test passed'),
    );
  });
} 