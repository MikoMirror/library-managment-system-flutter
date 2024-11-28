import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AppEmailSettings {
  final String email;
  final String displayName;
  final String accessToken;

  AppEmailSettings({
    required this.email,
    required this.displayName,
    required this.accessToken,
  });

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'accessToken': accessToken,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory AppEmailSettings.fromMap(Map<String, dynamic> map) {
    return AppEmailSettings(
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      accessToken: map['accessToken'] ?? '',
    );
  }
}

class SettingsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/gmail.send',
    ],
  );

  Future<AppEmailSettings?> getAppEmailSettings() async {
    final doc = await _firestore.collection('settings').doc('email').get();
    if (doc.exists) {
      return AppEmailSettings.fromMap(doc.data()!);
    }
    return null;
  }

  Future<bool> connectGoogleAccount() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account != null) {
        final GoogleSignInAuthentication auth = await account.authentication;
        
        final settings = AppEmailSettings(
          email: account.email,
          displayName: account.displayName ?? 'Library System',
          accessToken: auth.accessToken ?? '',
        );

        await _firestore.collection('settings').doc('email').set(settings.toMap());
        return true;
      }
      return false;
    } catch (e) {
      print('Error connecting Google account: $e');
      return false;
    }
  }

  Future<void> disconnectGoogleAccount() async {
    try {
      await _googleSignIn.signOut();
      await _firestore.collection('settings').doc('email').delete();
    } catch (e) {
      print('Error disconnecting Google account: $e');
    }
  }

  Stream<DocumentSnapshot> watchEmailSettings() {
    return _firestore.collection('settings').doc('email').snapshots();
  }
} 