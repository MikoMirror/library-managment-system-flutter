import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../../../core/repositories/base_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UsersRepository implements BaseRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  UsersRepository({
    required FirebaseFirestore firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore,
       _auth = auth ?? FirebaseAuth.instance;

  Stream<List<UserModel>> getAllUsers() {
    return _firestore
        .collection('users')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromMap(doc.data()))
            .toList());
  }

  Stream<List<UserModel>> searchUsers(String query) {
    query = query.toLowerCase();
    return _firestore
        .collection('users')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromMap(doc.data()))
            .where((user) =>
                user.name.toLowerCase().contains(query) ||
                user.email.toLowerCase().contains(query) ||
                user.libraryNumber.toLowerCase().contains(query))
            .toList());
  }

  Future<void> deleteUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).delete();
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
      // Store current admin user if exists
      final currentUser = _auth.currentUser;
      String? adminToken;
      if (currentUser != null) {
        adminToken = await currentUser.getIdToken();
      }

      // Create the new user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create the user model
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

      // Save user data to Firestore
      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(user.toMap());

      // Restore admin session if credentials provided
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

  Future<void> createInitialAdmin({
    required String name,
    required String phoneNumber,
    required String pesel,
    required String email,
    required String password,
  }) async {
    try {
      await createUser(
        name: name,
        phoneNumber: phoneNumber,
        pesel: pesel,
        email: email,
        password: password,
        role: 'admin',
      );
    } catch (e) {
      throw Exception('Failed to create initial admin: $e');
    }
  }

  String _generateLibraryNumber() {
    final now = DateTime.now();
    final random = now.microsecondsSinceEpoch % 10000;
    return 'LIB${now.year}${random.toString().padLeft(4, '0')}';
  }

  Future<bool> adminExists() async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check for admin existence: $e');
    }
  }

  @override
  void dispose() {
    // Clean up any resources if needed
  }
} 