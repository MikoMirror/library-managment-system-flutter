import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> setupFirebaseEmulators() async {
  // Set up Firebase Auth emulator
  await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
  
  // Set up Firestore emulator
  FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
  
  // Optional: Set up Functions emulator if you're using Cloud Functions
  // FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);
}

Future<void> clearEmulatorData() async {
  // Clear Firestore data
  final collections = [
    'users',
    'books',
    'reservations',
    'notifications',
    // Add any other collection names your app uses
  ];

  for (final collectionName in collections) {
    final collection = FirebaseFirestore.instance.collection(collectionName);
    final snapshots = await collection.get();
    for (final doc in snapshots.docs) {
      await doc.reference.delete();
    }
  }

  // Sign out any authenticated user
  await FirebaseAuth.instance.signOut();
} 