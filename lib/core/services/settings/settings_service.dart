import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<DocumentSnapshot> getEmailSettings() async {
    return await _firestore.collection('settings').doc('email').get();
  }

  Future<void> updateEmailSettings(Map<String, dynamic> settings) async {
    await _firestore.collection('settings').doc('email').set(settings);
  }

  Future<DocumentSnapshot> getAppSettings() async {
    return await _firestore.collection('settings').doc('app').get();
  }

  Future<void> updateAppSettings(Map<String, dynamic> settings) async {
    await _firestore.collection('settings').doc('app').set(settings);
  }
} 