import 'package:cloud_firestore/cloud_firestore.dart';

class LibrarySettingsService {
  final FirebaseFirestore _firestore;
  static const String settingsCollection = 'library_settings';
  static const String generalDoc = 'general';

  LibrarySettingsService({FirebaseFirestore? firestore}) 
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> updateMaxAdvanceReservationDays(int days) async {
    await _firestore
        .collection(settingsCollection)
        .doc(generalDoc)
        .set({
          'maxAdvanceReservationDays': days,
        }, SetOptions(merge: true));
  }

  Stream<int> getMaxAdvanceReservationDays() {
    return _firestore
        .collection(settingsCollection)
        .doc(generalDoc)
        .snapshots()
        .map((snapshot) => 
            snapshot.data()?['maxAdvanceReservationDays'] as int? ?? 5);
  }
} 