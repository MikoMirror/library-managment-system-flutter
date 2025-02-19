import '../models/user_model.dart';

abstract class UsersState {}

class UsersInitial extends UsersState {}

class UsersLoading extends UsersState {}

class UsersLoaded extends UsersState {
  final List<UserModel> users;

  UsersLoaded(this.users);
}

class UsersError extends UsersState {
  final String message;

  UsersError(this.message);
}

class UserCreating extends UsersState {}

class UserCreated extends UsersState {}

class UserUpdating extends UsersState {}

class UserUpdated extends UsersState {} 