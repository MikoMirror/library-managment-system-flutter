import '../models/user_model.dart';
import '../../../core/repositories/base_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/firestore/users_firestore_service.dart';

class UsersRepository implements BaseRepository {
  final UsersFirestoreService _firestoreService;
  final FirebaseAuth _auth;

  UsersRepository({
    required UsersFirestoreService firestoreService,
    FirebaseAuth? auth,
  }) : _firestoreService = firestoreService,
       _auth = auth ?? FirebaseAuth.instance;

  Stream<List<UserModel>> getAllUsers() {
    return _firestoreService.getUsersStream();
  }

  Stream<List<UserModel>> searchUsers(String query) {
    query = query.toLowerCase();
    return _firestoreService.getUsersStream().map((users) => users
        .where((user) =>
            user.name.toLowerCase().contains(query) ||
            user.email.toLowerCase().contains(query) ||
            user.libraryNumber.toLowerCase().contains(query))
        .toList());
  }

  Future<void> deleteUser(String userId) async {
    try {
      await _firestoreService.deleteDocument(UsersFirestoreService.collectionPath, userId);
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  Future<void> createUser({
    required String name,
    required String phoneNumber,
    required String pesel,
    required String email,
    required String password,
    required String role,
    String? adminEmail,
    String? adminPassword,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = UserModel(
        userId: userCredential.user!.uid,
        name: name,
        phoneNumber: phoneNumber,
        pesel: pesel,
        email: email,
        role: role,
        createdAt: DateTime.now(),
        libraryNumber: _generateLibraryNumber(),
      );

      await _firestoreService.createUser(user);

      if (adminEmail != null && adminPassword != null) {
        await _auth.signInWithEmailAndPassword(
          email: adminEmail,
          password: adminPassword,
        );
      }
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }

  Future<bool> adminExists() async {
    try {
      final querySnapshot = await _firestoreService.firestore
          .collection(UsersFirestoreService.collectionPath)
          .where('role', isEqualTo: 'admin')
          .limit(1)
          .get();
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check if admin exists: $e');
    }
  }

  String _generateLibraryNumber() {
    final now = DateTime.now();
    final random = now.microsecondsSinceEpoch % 10000;
    return 'LIB${now.year}${random.toString().padLeft(4, '0')}';
  }

  Future<void> createInitialAdmin({
    required String name,
    required String phoneNumber,
    required String pesel,
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = UserModel(
        userId: userCredential.user!.uid,
        name: name,
        phoneNumber: phoneNumber,
        pesel: pesel,
        email: email,
        role: 'admin',
        createdAt: DateTime.now(),
        libraryNumber: _generateLibraryNumber(),
      );

      await _firestoreService.createUser(user);
    } catch (e) {
      throw Exception('Failed to create initial admin: $e');
    }
  }

  Future<void> updateUser({
    required String userId,
    required String name,
    required String phoneNumber,
    required String pesel,
    required String email,
    required String role,
    String? adminEmail,
    String? adminPassword,
  }) async {
    try {
      // Re-authenticate admin if credentials provided
      if (adminEmail != null && adminPassword != null) {
        await _auth.signInWithEmailAndPassword(
          email: adminEmail,
          password: adminPassword,
        );
      }

      // Update user data in Firestore
      final userData = {
        'name': name,
        'phoneNumber': phoneNumber,
        'pesel': pesel,
        'email': email,
        'role': role,
      };

      await _firestoreService.updateDocument(
        UsersFirestoreService.collectionPath,
        userId,
        userData,
      );

      // Re-authenticate admin after update
      if (adminEmail != null && adminPassword != null) {
        await _auth.signInWithEmailAndPassword(
          email: adminEmail,
          password: adminPassword,
        );
      }
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  @override
  void dispose() {
    // Clean up any resources if needed
  }
} 