import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:library_management_system/features/users/repositories/users_repository.dart';
import 'package:library_management_system/core/services/firestore/users_firestore_service.dart';
import 'package:library_management_system/features/users/models/user_model.dart';
import 'users_repository_test.mocks.dart';

@GenerateMocks([
  UsersFirestoreService,
  FirebaseAuth,
  UserCredential,
  User,
  FirebaseFirestore,
], customMocks: [
  MockSpec<CollectionReference<Map<String, dynamic>>>(
    as: #MockCollectionReference,
  ),
  MockSpec<Query<Map<String, dynamic>>>(
    as: #MockQuery,
  ),
  MockSpec<QuerySnapshot<Map<String, dynamic>>>(
    as: #MockQuerySnapshot,
  ),
])
void main() {
  late UsersRepository repository;
  late MockUsersFirestoreService mockFirestoreService;
  late MockFirebaseAuth mockAuth;
  late MockUserCredential mockUserCredential;
  late MockUser mockUser;
  late MockFirebaseFirestore mockFirestore;
  late MockQuery mockQuery;
  late MockQuerySnapshot mockQuerySnapshot;
  late MockCollectionReference mockCollection;

  setUp(() {
    print('📝 Setting up test environment...');
    mockFirestoreService = MockUsersFirestoreService();
    mockAuth = MockFirebaseAuth();
    mockUserCredential = MockUserCredential();
    mockUser = MockUser();
    mockFirestore = MockFirebaseFirestore();
    mockQuery = MockQuery();
    mockQuerySnapshot = MockQuerySnapshot();
    mockCollection = MockCollectionReference();

    when(mockUserCredential.user).thenReturn(mockUser);
    when(mockUser.uid).thenReturn('test-uid');
    when(mockFirestoreService.firestore).thenReturn(mockFirestore);
    when(mockFirestore.collection(any))
        .thenReturn(mockCollection as CollectionReference<Map<String, dynamic>>);
    when(mockCollection.where(any, isEqualTo: anyNamed('isEqualTo'))).thenReturn(mockQuery);
    when(mockQuery.limit(any)).thenReturn(mockQuery);
    when(mockQuery.get()).thenAnswer((_) => Future.value(mockQuerySnapshot));
    when(mockQuerySnapshot.docs).thenReturn([]);

    repository = UsersRepository(
      firestoreService: mockFirestoreService,
      auth: mockAuth,
    );
  });

  group('UsersRepository', () {
    final mockUserModel = UserModel(
      userId: 'test-uid',
      name: 'Test User',
      phoneNumber: '123456789',
      pesel: '12345678901',
      email: 'test@test.com',
      role: 'user',
      createdAt: DateTime.now(),
      libraryNumber: 'LIB123',
    );

    test('getAllUsers returns stream of users', () {
      print('👥 Testing getAllUsers stream...');
      when(mockFirestoreService.getUsersStream())
          .thenAnswer((_) => Stream.value([mockUserModel]));

      final stream = repository.getAllUsers();
      expect(stream, emits([mockUserModel]));
      print('✅ getAllUsers test passed');
    });

    test('createUser creates new user', () async {
      print('👤 Testing user creation...');
      when(mockAuth.createUserWithEmailAndPassword(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) => Future.value(mockUserCredential));

      when(mockFirestoreService.createUser(any))
          .thenAnswer((_) => Future.value());

      await repository.createUser(
        name: 'Test User',
        phoneNumber: '123456789',
        pesel: '12345678901',
        email: 'test@test.com',
        password: 'password123',
        role: 'user',
      );

      verify(mockAuth.createUserWithEmailAndPassword(
        email: 'test@test.com',
        password: 'password123',
      )).called(1);
      verify(mockFirestoreService.createUser(any)).called(1);
      print('✅ User creation test passed');
    });

    test('updateUser updates user data', () async {
      print('📝 Testing user update...');
      when(mockFirestoreService.updateDocument(any, any, any))
          .thenAnswer((_) => Future.value());

      await repository.updateUser(
        userId: 'test-uid',
        name: 'Updated User',
        phoneNumber: '987654321',
        pesel: '10987654321',
        email: 'updated@test.com',
        role: 'user',
      );

      verify(mockFirestoreService.updateDocument(
        UsersFirestoreService.collectionPath,
        'test-uid',
        any,
      )).called(1);
      print('✅ User update test passed');
    });

    test('adminExists checks for admin user', () async {
      print('👑 Testing admin existence check...');
      await repository.adminExists();

      verify(mockFirestore.collection(UsersFirestoreService.collectionPath)).called(1);
      verify(mockCollection.where('role', isEqualTo: 'admin')).called(1);
      verify(mockQuery.limit(1)).called(1);
      verify(mockQuery.get()).called(1);
      print('✅ Admin existence check test passed');
    });

    test('createInitialAdmin creates admin user', () async {
      print('👑 Testing initial admin creation...');
      when(mockAuth.createUserWithEmailAndPassword(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) => Future.value(mockUserCredential));

      when(mockFirestoreService.createUser(any))
          .thenAnswer((_) => Future.value());

      await repository.createInitialAdmin(
        name: 'Admin User',
        phoneNumber: '123456789',
        pesel: '12345678901',
        email: 'admin@test.com',
        password: 'admin123',
      );

      verify(mockAuth.createUserWithEmailAndPassword(
        email: 'admin@test.com',
        password: 'admin123',
      )).called(1);
      verify(mockFirestoreService.createUser(any)).called(1);
      print('✅ Initial admin creation test passed');
    });
  });

  tearDown(() {
    print('🧹 Cleaning up test environment...');
  });
} 