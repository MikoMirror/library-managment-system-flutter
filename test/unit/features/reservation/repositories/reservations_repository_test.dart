import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:library_management_system/features/reservation/repositories/reservation_repository.dart';
import 'package:library_management_system/core/services/firestore/reservations_firestore_service.dart';
import 'package:library_management_system/core/services/firestore/books_firestore_service.dart';
import 'package:library_management_system/core/services/firestore/users_firestore_service.dart';
import 'reservations_repository_test.mocks.dart';

@GenerateMocks([
  ReservationsFirestoreService,
  BooksFirestoreService,
  UsersFirestoreService,
], customMocks: [
  MockSpec<DocumentReference<Map<String, dynamic>>>(
    as: #MockDocumentReference,
  ),
  MockSpec<DocumentSnapshot<Map<String, dynamic>>>(
    as: #MockDocumentSnapshot,
  ),
  MockSpec<QuerySnapshot<Map<String, dynamic>>>(
    as: #MockQuerySnapshot,
  ),
  MockSpec<CollectionReference<Map<String, dynamic>>>(
    as: #MockCollectionReference,
  ),
  MockSpec<WriteBatch>(
    as: #MockWriteBatch,
  ),
])
void main() {
  late ReservationsRepository repository;
  late MockReservationsFirestoreService mockReservationsService;
  late MockBooksFirestoreService mockBooksService;
  late MockUsersFirestoreService mockUsersService;
  late MockDocumentReference mockDocumentReference;
  late MockDocumentSnapshot mockDocumentSnapshot;
  late MockCollectionReference mockCollectionReference;
  late MockWriteBatch mockWriteBatch;
  late MockQuerySnapshot mockQuerySnapshot;

  setUp(() {
    print('🔧 Setting up ReservationsRepository test suite...');
    mockReservationsService = MockReservationsFirestoreService();
    mockBooksService = MockBooksFirestoreService();
    mockUsersService = MockUsersFirestoreService();
    mockDocumentReference = MockDocumentReference();
    mockDocumentSnapshot = MockDocumentSnapshot();
    mockCollectionReference = MockCollectionReference();
    mockWriteBatch = MockWriteBatch();
    mockQuerySnapshot = MockQuerySnapshot();
    
    repository = ReservationsRepository(
      reservationsService: mockReservationsService,
      booksService: mockBooksService,
      usersService: mockUsersService,
    );
    print('✨ Repository initialized with mock services');

    // Setup common stubs
    print('📚 Configuring mock behaviors...');
    when(mockReservationsService.batch()).thenReturn(mockWriteBatch);
    when(mockWriteBatch.commit()).thenAnswer((_) => Future.value());
    when(mockReservationsService.collection(any)).thenReturn(mockCollectionReference);
    when(mockCollectionReference.doc(any)).thenReturn(mockDocumentReference);
    when(mockDocumentReference.get()).thenAnswer((_) => Future.value(mockDocumentSnapshot));
    when(mockDocumentSnapshot.exists).thenReturn(true);
    when(mockDocumentSnapshot.data()).thenReturn({
      'userId': 'user1',
      'bookId': 'book1',
      'status': 'reserved',
      'quantity': 1,
    });
    when(mockDocumentSnapshot.reference).thenReturn(mockDocumentReference);
    when(mockReservationsService.getExpiredReservations(any))
        .thenAnswer((_) => Future.value(mockQuerySnapshot));
    when(mockQuerySnapshot.docs).thenReturn([]);
    print('✅ Mock configurations completed');
  });

  tearDown(() {
    print('🧹 Cleaning up test resources...');
    repository.dispose();
    print('🚫 Repository disposed');
  });

  group('ReservationsRepository', () {
    test('createReservation creates new reservation', () async {
      print('🏗️ Setting up createReservation test...');
      
      // Additional setup for createReservation
      when(mockBooksService.getDocumentReference(any, any))
          .thenReturn(mockDocumentReference);
      when(mockReservationsService.createReservation(any))
          .thenAnswer((_) => Future.value(mockDocumentReference));
      print('📚 Mock repository configured for reservation creation');
      
      print('▶️ Executing createReservation...');
      await repository.createReservation(
        userId: 'user1',
        bookId: 'book1',
        status: 'reserved',
        borrowedDate: Timestamp.now(),
        dueDate: Timestamp.now(),
        quantity: 1,
      );

      print('✅ Verifying createReservation execution...');
      verify(mockReservationsService.createReservation(any)).called(1);
      verify(mockWriteBatch.commit()).called(1);
      print('📝 Reservation creation verified successfully');
    });

    test('updateReservationStatus updates status', () async {
      print('🏗️ Setting up updateReservationStatus test...');
      
      print('▶️ Executing updateReservationStatus...');
      await repository.updateReservationStatus(
        reservationId: '1',
        newStatus: 'borrowed',
      );

      print('✅ Verifying status update...');
      verify(mockWriteBatch.update(any, any)).called(1);
      verify(mockWriteBatch.commit()).called(1);
      print('📝 Status update verified successfully');
    });

    test('checkExpiredReservations processes expired reservations', () async {
      print('🏗️ Setting up checkExpiredReservations test...');
      
      print('▶️ Executing checkExpiredReservations...');
      await repository.checkExpiredReservations();

      print('✅ Verifying expired reservations check...');
      verify(mockReservationsService.getExpiredReservations(any)).called(1);
      print('📝 Expired reservations check verified successfully');
    });

    test('validateReservationDate validates date correctly', () async {
      print('🏗️ Setting up validateReservationDate test...');
      
      when(mockReservationsService.validateReservationDate(any))
          .thenAnswer((_) => Future.value(true));
      print('📚 Mock configured for date validation');

      print('▶️ Executing validateReservationDate...');
      final result = await repository.validateReservationDate(DateTime.now());
      
      print('✅ Verifying date validation...');
      expect(result, isTrue);
      print('📝 Date validation verified successfully');
    });

    test('startPeriodicCheck starts timer correctly', () async {
      print('🏗️ Setting up startPeriodicCheck test...');
      
      print('▶️ Starting periodic check...');
      repository.startPeriodicCheck();
      
      print('⏳ Waiting for initial check...');
      await Future.delayed(const Duration(milliseconds: 100));
      
      print('✅ Verifying periodic check...');
      verify(mockReservationsService.getExpiredReservations(any)).called(1);
      print('📝 Periodic check verified successfully');
      
      print('🧹 Cleaning up timer...');
      repository.dispose();
      print('🚫 Timer disposed');
    });
  });
} 