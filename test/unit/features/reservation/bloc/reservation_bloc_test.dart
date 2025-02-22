import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:library_management_system/features/reservation/bloc/reservation_bloc.dart';
import 'package:library_management_system/features/reservation/repositories/reservation_repository.dart';
import 'package:library_management_system/features/reservation/models/reservation.dart';
import 'reservation_bloc_test.mocks.dart';

@GenerateMocks([ReservationsRepository])
void main() {
  late ReservationBloc bloc;
  late MockReservationsRepository mockRepository;

  setUp(() {
    print('🔧 Setting up ReservationBloc test suite...');
    mockRepository = MockReservationsRepository();
    bloc = ReservationBloc(repository: mockRepository);
    print('✨ ReservationBloc initialized with mock repository');
  });

  tearDown(() {
    print('🧹 Cleaning up ReservationBloc test resources...');
    bloc.close();
    print('🚫 ReservationBloc closed');
  });

  group('ReservationBloc', () {
    final now = Timestamp.now();
    final mockReservations = [
      Reservation(
        id: '1',
        userId: 'user1',
        bookId: 'book1',
        status: 'reserved',
        borrowedDate: now,
        dueDate: now,
        quantity: 1,
        bookTitle: 'Test Book',
        userName: 'Test User',
        userLibraryNumber: 'LIB123',
      ),
    ];

    blocTest<ReservationBloc, ReservationState>(
      'emits [ReservationLoading, ReservationsLoaded] when LoadReservations is added',
      build: () {
        print('🏗️ Building LoadReservations test...');
        when(mockRepository.getReservations())
            .thenAnswer((_) => Future.value(mockReservations));
        print('📚 Mock repository configured to return ${mockReservations.length} reservation(s)');
        return bloc;
      },
      act: (bloc) {
        print('▶️ Dispatching LoadReservations event');
        bloc.add(LoadReservations());
      },
      expect: () => [
        isA<ReservationLoading>(),
        isA<ReservationsLoaded>(),
      ],
      verify: (_) {
        print('✅ Verifying LoadReservations results');
        expect((bloc.state as ReservationsLoaded).reservations.length, 1);
        print('📊 Found ${(bloc.state as ReservationsLoaded).reservations.length} reservation(s)');
      },
    );

    blocTest<ReservationBloc, ReservationState>(
      'emits [ReservationLoading, ReservationSuccess] when CreateReservation is added',
      build: () {
        print('🏗️ Building CreateReservation test...');
        when(mockRepository.validateReservationDate(any))
            .thenAnswer((_) => Future.value(true));
        when(mockRepository.createReservation(
          userId: anyNamed('userId'),
          bookId: anyNamed('bookId'),
          status: anyNamed('status'),
          borrowedDate: anyNamed('borrowedDate'),
          dueDate: anyNamed('dueDate'),
          quantity: anyNamed('quantity'),
        )).thenAnswer((_) async => Future.value());
        when(mockRepository.getReservations())
            .thenAnswer((_) => Future.value(mockReservations));
        print('📚 Mock repository configured for reservation creation');
        return bloc;
      },
      act: (bloc) {
        print('▶️ Dispatching CreateReservation event');
        bloc.add(CreateReservation(
          userId: 'user1',
          bookId: 'book1',
          quantity: 1,
          borrowedDate: now,
          dueDate: now,
        ));
      },
      expect: () => [
        ReservationLoading(),
        ReservationSuccess(),
        ReservationLoading(),
        ReservationsLoaded(mockReservations),
      ],
      verify: (_) {
        print('✅ Verifying CreateReservation execution');
        verify(mockRepository.createReservation(
          userId: 'user1',
          bookId: 'book1',
          status: 'reserved',
          borrowedDate: now,
          dueDate: now,
          quantity: 1,
        )).called(1);
        print('📝 Reservation creation verified successfully');
      },
    );
  });
} 