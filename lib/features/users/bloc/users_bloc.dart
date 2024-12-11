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
} 