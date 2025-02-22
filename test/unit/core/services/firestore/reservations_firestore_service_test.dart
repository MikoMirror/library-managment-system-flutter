import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:library_management_system/core/services/firestore/reservations_firestore_service.dart';
import 'reservations_firestore_service_test.mocks.dart';

@GenerateMocks([
  FirebaseFirestore,
  Logger,
], customMocks: [
  MockSpec<DocumentReference<Map<String, dynamic>>>(as: #MockDocumentReference),
  MockSpec<DocumentSnapshot<Map<String, dynamic>>>(as: #MockDocumentSnapshot),
  MockSpec<CollectionReference<Map<String, dynamic>>>(as: #MockCollectionReference),
])
void main() {
  late ReservationsFirestoreService service;
  late MockFirebaseFirestore mockFirestore;
  late MockLogger mockLogger;
  late MockDocumentReference mockSettingsDoc;
  late MockDocumentSnapshot mockSettingsSnapshot;
  late MockCollectionReference mockCollection;

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockLogger = MockLogger();
    mockSettingsDoc = MockDocumentReference();
    mockSettingsSnapshot = MockDocumentSnapshot();
    mockCollection = MockCollectionReference();
    
    // Create service with mock Firestore instance and mock logger
    service = ReservationsFirestoreService.withFirestore(
      mockFirestore,
      logger: mockLogger,
    );

    // Setup common mock behaviors
    when(mockFirestore.collection('library_settings'))
        .thenReturn(mockCollection);
    when(mockCollection.doc('general'))
        .thenReturn(mockSettingsDoc);
  });

  group('validateReservationDate', () {
    test('returns true for valid reservation date within max advance days', () async {
      // Arrange
      final now = DateTime.now();
      final validDate = DateTime(now.year, now.month, now.day + 3); // 3 days ahead
      
      when(mockSettingsDoc.get())
          .thenAnswer((_) async => mockSettingsSnapshot);
      when(mockSettingsSnapshot.data())
          .thenReturn({'maxAdvanceReservationDays': 5});

      // Act
      final isValid = await service.validateReservationDate(validDate);

      // Assert
      expect(isValid, true);
      verify(mockFirestore.collection('library_settings')).called(1);
      verify(mockSettingsDoc.get()).called(1);
    });

    test('returns false for reservation date beyond max advance days', () async {
      // Arrange
      final now = DateTime.now();
      final invalidDate = DateTime(now.year, now.month, now.day + 7); // 7 days ahead
      
      when(mockSettingsDoc.get())
          .thenAnswer((_) async => mockSettingsSnapshot);
      when(mockSettingsSnapshot.data())
          .thenReturn({'maxAdvanceReservationDays': 5});

      // Act
      final isValid = await service.validateReservationDate(invalidDate);

      // Assert
      expect(isValid, false);
      verify(mockFirestore.collection('library_settings')).called(1);
      verify(mockSettingsDoc.get()).called(1);
    });

    test('returns false when settings document fetch fails', () async {
      // Arrange
      final now = DateTime.now();
      final validDate = DateTime(now.year, now.month, now.day + 3);
      
      when(mockSettingsDoc.get())
          .thenThrow(Exception('Failed to fetch settings'));

      // Act
      final isValid = await service.validateReservationDate(validDate);

      // Assert
      expect(isValid, false);
      verify(mockFirestore.collection('library_settings')).called(1);
      verify(mockSettingsDoc.get()).called(1);
    });
  });
} 