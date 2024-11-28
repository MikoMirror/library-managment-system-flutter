import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> createUser(
    String name,
    String phoneNumber,
    String pesel,
    String email,
    String password,
    String role,
  ) async {
    // Create auth user without signing in
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Create user document (without password)
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

    // Save to Firestore
    await _firestore
        .collection('users')
        .doc(userCredential.user!.uid)
        .set(user.toMap());

    // Sign out the newly created user to keep the admin signed in
    await _auth.signOut();
  }

  String _generateLibraryNumber() {
    final now = DateTime.now();
    final random = now.microsecondsSinceEpoch % 10000;
    return 'LIB${now.year}${random.toString().padLeft(4, '0')}';
  }
} 