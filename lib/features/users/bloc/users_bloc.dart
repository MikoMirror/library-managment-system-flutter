import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/users_repository.dart';
import '../models/user_model.dart';
import 'users_event.dart';
import 'users_state.dart';

class UsersBloc extends Bloc<UsersEvent, UsersState> {
  final UsersRepository _repository;

  UsersBloc({required UsersRepository repository})
      : _repository = repository,
        super(UsersInitial()) {
    on<LoadUsers>(_onLoadUsers);
    on<SearchUsers>(_onSearchUsers);
    on<CreateUser>(_onCreateUser);
    on<UpdateUser>(_onUpdateUser);
  }

  Future<void> _onLoadUsers(LoadUsers event, Emitter<UsersState> emit) async {
    emit(UsersLoading());
    try {
      await emit.forEach(
        _repository.getAllUsers(),
        onData: (List<UserModel> users) => UsersLoaded(users),
        onError: (error, stackTrace) => UsersError(error.toString()),
      );
    } catch (e) {
      emit(UsersError(e.toString()));
    }
  }

  Future<void> _onSearchUsers(SearchUsers event, Emitter<UsersState> emit) async {
    emit(UsersLoading());
    try {
      await emit.forEach(
        _repository.searchUsers(event.query),
        onData: (List<UserModel> users) => UsersLoaded(users),
        onError: (error, stackTrace) => UsersError(error.toString()),
      );
    } catch (e) {
      emit(UsersError(e.toString()));
    }
  }

  Future<void> _onCreateUser(CreateUser event, Emitter<UsersState> emit) async {
    emit(UserCreating());
    try {
      await _repository.createUser(
        name: event.name,
        phoneNumber: event.phoneNumber,
        pesel: event.pesel,
        email: event.email,
        password: event.password,
        role: event.role,
      );
      emit(UserCreated());
      add(LoadUsers()); // Reload the users list
    } catch (e) {
      emit(UsersError(e.toString()));
    }
  }

  Future<void> _onUpdateUser(UpdateUser event, Emitter<UsersState> emit) async {
    emit(UserUpdating());
    try {
      await _repository.updateUser(
        userId: event.userId,
        name: event.name,
        phoneNumber: event.phoneNumber,
        pesel: event.pesel,
        email: event.email,
        role: event.role,
        adminEmail: event.adminEmail,
        adminPassword: event.adminPassword,
      );
      emit(UserUpdated());
      add(LoadUsers()); // Reload the users list
    } catch (e) {
      emit(UsersError(e.toString()));
    }
  }
} 