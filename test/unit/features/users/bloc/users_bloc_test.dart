import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:library_management_system/features/users/bloc/users_bloc.dart';
import 'package:library_management_system/features/users/bloc/users_event.dart';
import 'package:library_management_system/features/users/bloc/users_state.dart';
import 'package:library_management_system/features/users/repositories/users_repository.dart';
import 'package:library_management_system/features/users/models/user_model.dart';
import 'users_bloc_test.mocks.dart'; // Import the generated mocks

@GenerateMocks([UsersRepository])
void main() {
  late UsersBloc bloc;
  late MockUsersRepository mockRepository;

  setUp(() {
    print('📝 Setting up test environment...');
    mockRepository = MockUsersRepository();
    bloc = UsersBloc(repository: mockRepository);
  });

  tearDown(() {
    print('🧹 Cleaning up test environment...');
    bloc.close();
  });

  group('UsersBloc', () {
    final mockUsers = [
      UserModel(
        userId: '1',
        name: 'Test User',
        phoneNumber: '123456789',
        pesel: '12345678901',
        email: 'test@test.com',
        role: 'user',
        createdAt: DateTime.now(),
        libraryNumber: 'LIB123',
      ),
    ];

    blocTest<UsersBloc, UsersState>(
      'emits [UsersLoading, UsersLoaded] when LoadUsers is added',
      setUp: () => print('📚 Testing LoadUsers event...'),
      build: () {
        when(mockRepository.getAllUsers())
            .thenAnswer((_) => Stream.value(mockUsers));
        return bloc;
      },
      act: (bloc) => bloc.add(LoadUsers()),
      expect: () => [
        isA<UsersLoading>(),
        isA<UsersLoaded>().having((state) => state.users, 'users', mockUsers),
      ],
      verify: (_) => print('✅ LoadUsers test passed'),
    );

    blocTest<UsersBloc, UsersState>(
      'emits [UsersLoading, UsersLoaded] when SearchUsers is added',
      setUp: () => print('🔍 Testing SearchUsers event...'),
      build: () {
        when(mockRepository.searchUsers(any))
            .thenAnswer((_) => Stream.value(mockUsers));
        return bloc;
      },
      act: (bloc) => bloc.add(SearchUsers('test')),
      expect: () => [
        isA<UsersLoading>(),
        isA<UsersLoaded>().having((state) => state.users, 'users', mockUsers),
      ],
      verify: (_) => print('✅ SearchUsers test passed'),
    );

    blocTest<UsersBloc, UsersState>(
      'emits [UserCreating, UserCreated, UsersLoading, UsersLoaded] when CreateUser is added',
      setUp: () => print('👤 Testing CreateUser event...'),
      build: () {
        when(mockRepository.createUser(
          name: anyNamed('name'),
          phoneNumber: anyNamed('phoneNumber'),
          pesel: anyNamed('pesel'),
          email: anyNamed('email'),
          password: anyNamed('password'),
          role: anyNamed('role'),
        )).thenAnswer((_) => Future.value());
        when(mockRepository.getAllUsers())
            .thenAnswer((_) => Stream.value(mockUsers));
        return bloc;
      },
      act: (bloc) => bloc.add(CreateUser(
        name: 'New User',
        phoneNumber: '987654321',
        pesel: '10987654321',
        email: 'new@test.com',
        password: 'password123',
        role: 'user',
      )),
      expect: () => [
        isA<UserCreating>(),
        isA<UserCreated>(),
        isA<UsersLoading>(),
        isA<UsersLoaded>().having((state) => state.users, 'users', mockUsers),
      ],
      verify: (_) => print('✅ CreateUser test passed'),
    );

    blocTest<UsersBloc, UsersState>(
      'emits [UserUpdating, UserUpdated, UsersLoading, UsersLoaded] when UpdateUser is added',
      setUp: () => print('📝 Testing UpdateUser event...'),
      build: () {
        when(mockRepository.updateUser(
          userId: anyNamed('userId'),
          name: anyNamed('name'),
          phoneNumber: anyNamed('phoneNumber'),
          pesel: anyNamed('pesel'),
          email: anyNamed('email'),
          role: anyNamed('role'),
          adminEmail: anyNamed('adminEmail'),
          adminPassword: anyNamed('adminPassword'),
        )).thenAnswer((_) => Future.value());
        when(mockRepository.getAllUsers())
            .thenAnswer((_) => Stream.value(mockUsers));
        return bloc;
      },
      act: (bloc) => bloc.add(UpdateUser(
        userId: '1',
        name: 'Updated User',
        phoneNumber: '987654321',
        pesel: '10987654321',
        email: 'updated@test.com',
        role: 'user',
        adminEmail: 'admin@test.com',
        adminPassword: 'admin123',
      )),
      expect: () => [
        isA<UserUpdating>(),
        isA<UserUpdated>(),
        isA<UsersLoading>(),
        isA<UsersLoaded>().having((state) => state.users, 'users', mockUsers),
      ],
      verify: (_) => print('✅ UpdateUser test passed'),
    );
  });
} 