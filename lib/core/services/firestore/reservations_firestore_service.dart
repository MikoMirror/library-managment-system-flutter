import 'package:cloud_firestore/cloud_firestore.dart';
import 'base_firestore_service.dart';
import '../../../features/reservation/models/reservation.dart';
import 'package:logger/logger.dart';

class ReservationsFirestoreService extends BaseFirestoreService {
  static const String collectionPath = 'books_reservation';

  final _logger = Logger();

  CollectionReference<Map<String, dynamic>> collection(String path) {
    return firestore.collection(path);
  }

  WriteBatch batch() {
    return firestore.batch();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getReservations() {
    return collection(collectionPath).get();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> getReservationStream(String reservationId) {
    return collection(collectionPath).doc(reservationId).snapshots();
  }

  Future<void> updateReservationStatus(String reservationId, String newStatus) {
    return collection(collectionPath).doc(reservationId).update({
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getExpiredReservations(Timestamp cutoffTime) {
    return collection(collectionPath)
        .where('status', isEqualTo: 'reserved')
        .where('borrowedDate', isLessThan: cutoffTime)
        .get();
  }

  Future<void> addReservation(Reservation reservation) async {
    await addDocument(collectionPath, reservation.toMap());
  }

  Future<void> updateReservation(String id, Map<String, dynamic> data) async {
    await updateDocument(collectionPath, id, data);
  }

  Stream<List<Reservation>> getReservationsStream() {
    return getCollectionStream(
      collection: collectionPath,
      fromMap: (data, id) => Reservation.fromMap(data, id),
    );
  }

  Future<DocumentReference> createReservation(Map<String, dynamic> data) {
    return collection(collectionPath).add(data);
  }

  Future<void> deleteReservation(String id) async {
    await deleteDocument(collectionPath, id);
  }

  Future<bool> validateReservationDate(DateTime reservationDate) async {
    try {
      // Get the settings document
      final settingsDoc = await firestore
          .collection('library_settings')
          .doc('general')
          .get();
      
      final maxAdvanceDays = settingsDoc.data()?['maxAdvanceReservationDays'] as int? ?? 5;

      final now = DateTime.now();
      final lastAllowedDate = DateTime(
        now.year,
        now.month,
        now.day + maxAdvanceDays,
      );

      return reservationDate.isBefore(lastAllowedDate.add(const Duration(days: 1)));
    } catch (e) {
      _logger.e('Error validating reservation date: $e');
      return false;
    }
  }
} 