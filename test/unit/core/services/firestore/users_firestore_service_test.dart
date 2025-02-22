import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:library_management_system/core/services/firestore/users_firestore_service.dart';
import 'package:library_management_system/features/users/models/user_model.dart';
import 'users_firestore_service_test.mocks.dart';

@GenerateMocks([
  FirebaseFirestore,
], customMocks: [
  MockSpec<CollectionReference<Map<String, dynamic>>>(as: #MockUserCollection),
  MockSpec<DocumentReference<Map<String, dynamic>>>(as: #MockUserDocument),
  MockSpec<Query<Map<String, dynamic>>>(as: #MockUserQuery),
  MockSpec<QuerySnapshot<Map<String, dynamic>>>(as: #MockUserQuerySnapshot),
  MockSpec<DocumentSnapshot<Map<String, dynamic>>>(as: #MockUserDocumentSnapshot),
  MockSpec<QueryDocumentSnapshot<Map<String, dynamic>>>(as: #MockUserQueryDocumentSnapshot),
])
void main() {
  late UsersFirestoreService service;
  late MockFirebaseFirestore mockFirestore;
  late MockUserCollection mockCollection;
  late MockUserDocument mockDocument;
  late MockUserQuery mockQuery;
  late MockUserQuerySnapshot mockQuerySnapshot;
  late MockUserDocumentSnapshot mockDocSnapshot;
  late MockUserQueryDocumentSnapshot mockQueryDocSnapshot;

  setUp(() {
    print('🔧 Setting up UsersFirestoreService test suite...');
    mockFirestore = MockFirebaseFirestore();
    mockCollection = MockUserCollection();
    mockDocument = MockUserDocument();
    mockQuery = MockUserQuery();
    mockQuerySnapshot = MockUserQuerySnapshot();
    mockDocSnapshot = MockUserDocumentSnapshot();
    mockQueryDocSnapshot = MockUserQueryDocumentSnapshot();
    
    service = UsersFirestoreService.withFirestore(mockFirestore);

    // Common mock setups
    when(mockFirestore.collection(any)).thenReturn(mockCollection);
    when(mockCollection.doc(any)).thenReturn(mockDocument);
    print('✨ Test environment setup complete');
  });

  group('UsersFirestoreService', () {
    group('User Creation and Update', () {
      test('createUser creates new user successfully', () async {
        // Arrange
        final testUser = UserModel(
          userId: 'test-user-1',
          email: 'test@example.com',
          name: 'Test User',
          role: 'user',
          phoneNumber: '+48123456789',
          pesel: '12345678901',
          libraryNumber: 'LIB123',
          createdAt: DateTime.now(),
        );
        when(mockDocument.set(any)).thenAnswer((_) => Future.value());

        // Act
        await service.createUser(testUser);

        // Assert
        verify(mockFirestore.collection(UsersFirestoreService.collectionPath)).called(1);
        verify(mockCollection.doc(testUser.userId)).called(1);
        verify(mockDocument.set(testUser.toMap())).called(1);
      });

      test('updateUser updates existing user', () async {
        // Arrange
        const userId = 'test-user-1';
        final updateData = {'name': 'Updated Name'};
        when(mockDocument.update(any)).thenAnswer((_) => Future.value());

        // Act
        await service.updateUser(userId, updateData);

        // Assert
        verify(mockCollection.doc(userId)).called(1);
        verify(mockDocument.update(updateData)).called(1);
      });
    });

    group('User Retrieval', () {
      test('getUserById returns user when exists', () async {
        // Arrange
        const userId = 'test-user-1';
        final createdAt = DateTime.now();
        final userData = {
          'email': 'test@example.com',
          'name': 'Test User',
          'role': 'user',
          'phoneNumber': '+48123456789',
          'pesel': '12345678901',
          'libraryNumber': 'LIB123',
          'createdAt': createdAt.toIso8601String(),
        };

        when(mockDocSnapshot.exists).thenReturn(true);
        when(mockDocSnapshot.data()).thenReturn(userData);
        when(mockDocSnapshot.id).thenReturn(userId);
        when(mockDocument.get()).thenAnswer((_) => Future.value(mockDocSnapshot));

        // Act
        final user = await service.getUserById(userId);

        // Assert
        expect(user, isNotNull);
        expect(user?.email, equals(userData['email']));
        expect(user?.name, equals(userData['name']));
        verify(mockDocument.get()).called(1);
      });

      test('getUserById returns null when user does not exist', () async {
        // Arrange
        when(mockDocSnapshot.exists).thenReturn(false);
        when(mockDocument.get()).thenAnswer((_) => Future.value(mockDocSnapshot));

        // Act
        final user = await service.getUserById('non-existent-id');

        // Assert
        expect(user, isNull);
        verify(mockDocument.get()).called(1);
      });
    });

    group('User Search', () {
      test('searchUsers returns matching users', () async {
        // Arrange
        const query = 'test';
        final createdAt = DateTime.now();
        final mockUsers = [
          {
            'email': 'test1@example.com',
            'name': 'Test User 1',
            'role': 'user',
            'phoneNumber': '+48123456789',
            'pesel': '12345678901',
            'libraryNumber': 'LIB123',
            'createdAt': createdAt.toIso8601String(),
          }
        ];

        when(mockCollection.where('searchTerms', arrayContains: query))
            .thenReturn(mockQuery);
        when(mockQuery.get())
            .thenAnswer((_) => Future.value(mockQuerySnapshot));
        when(mockQuerySnapshot.docs)
            .thenReturn([mockQueryDocSnapshot]);
        when(mockQueryDocSnapshot.data()).thenReturn(mockUsers[0]);
        when(mockQueryDocSnapshot.id).thenReturn('user-1');

        // Act
        final results = await service.searchUsers(query);

        // Assert
        expect(results, isNotEmpty);
        expect(results.length, equals(1));
        expect(results.first.email, equals(mockUsers[0]['email']));
        verify(mockQuery.get()).called(1);
      });

      test('checkUserExists returns correct boolean', () async {
        // Arrange
        const email = 'test@example.com';
        when(mockCollection.where('email', isEqualTo: email))
            .thenReturn(mockQuery);
        when(mockQuery.get())
            .thenAnswer((_) => Future.value(mockQuerySnapshot));
        when(mockQuerySnapshot.docs).thenReturn([mockQueryDocSnapshot]);

        // Act
        final exists = await service.checkUserExists(email);

        // Assert
        expect(exists, isTrue);
        verify(mockQuery.get()).called(1);
      });
    });

    group('User Streams', () {
      test('getUserStream returns valid stream', () async {
        // Arrange
        const userId = 'test-user-1';
        when(mockDocument.snapshots())
            .thenAnswer((_) => Stream.value(mockDocSnapshot));

        // Act
        final stream = service.getUserStream(userId);

        // Assert
        expect(stream, isA<Stream<DocumentSnapshot<Map<String, dynamic>>>>());
        verify(mockDocument.snapshots()).called(1);
      });

      test('getUsersStream returns valid stream', () async {
        // Arrange
        when(mockCollection.snapshots())
            .thenAnswer((_) => Stream.value(mockQuerySnapshot));
        when(mockQuerySnapshot.docs).thenReturn([]);

        // Act
        final stream = service.getUsersStream();

        // Assert
        expect(stream, isA<Stream<List<UserModel>>>());
        verify(mockCollection.snapshots()).called(1);
      });
    });
  });
} 