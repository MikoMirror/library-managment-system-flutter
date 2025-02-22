import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> seedTestData() async {
  // Create test user
  final userCredential = await FirebaseAuth.instance
      .createUserWithEmailAndPassword(
        email: 'test@example.com',
        password: 'password123'
      );

  // Add test books
  await FirebaseFirestore.instance.collection('books').add({
    'title': 'Test Book',
    'author': 'Test Author',
    'isbn': '9781234567890',
    'booksQuantity': 5,
    'createdAt': FieldValue.serverTimestamp(),
  });

  // Add test user data
  await FirebaseFirestore.instance
      .collection('users')
      .doc(userCredential.user!.uid)
      .set({
        'name': 'Test User',
        'email': 'test@example.com',
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
      });
} 