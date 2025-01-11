abstract class UsersEvent {}

class LoadUsers extends UsersEvent {}

class SearchUsers extends UsersEvent {
  final String query;

  SearchUsers(this.query);
}

class CreateUser extends UsersEvent {
  final String name;
  final String phoneNumber;
  final String pesel;
  final String email;
  final String password;
  final String role;
  final String? adminEmail;
  final String? adminPassword;

  CreateUser({
    required this.name,
    required this.phoneNumber,
    required this.pesel,
    required this.email,
    required this.password,
    required this.role,
    this.adminEmail,
    this.adminPassword,
  });
}

class UpdateUser extends UsersEvent {
  final String userId;
  final String name;
  final String phoneNumber;
  final String pesel;
  final String email;
  final String role;
  final String? adminEmail;
  final String? adminPassword;

  UpdateUser({
    required this.userId,
    required this.name,
    required this.phoneNumber,
    required this.pesel,
    required this.email,
    required this.role,
    this.adminEmail,
    this.adminPassword,
  });
} 