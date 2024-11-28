
class UserModel {
  final String userId;
  final String name;
  final String email;
  final String phoneNumber;
  final String pesel;
  final String role;
  final DateTime createdAt;
  final String libraryNumber;

  UserModel({
    required this.userId,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.pesel,
    required this.role,
    required this.createdAt,
    required this.libraryNumber,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'pesel': pesel,
      'role': role,
      'createdAt': createdAt.toIso8601String(),
      'libraryNumber': libraryNumber,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      pesel: map['pesel'] ?? '',
      role: map['role'] ?? 'member',
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      libraryNumber: map['libraryNumber'] ?? '',
    );
  }
} 