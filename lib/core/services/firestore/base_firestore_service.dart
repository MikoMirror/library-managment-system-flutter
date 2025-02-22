import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meta/meta.dart';

abstract class BaseFirestoreService {
  final FirebaseFirestore _firestore;

  BaseFirestoreService() : _firestore = FirebaseFirestore.instance;
  
  @visibleForTesting
  BaseFirestoreService.withFirestore(FirebaseFirestore firestore) 
      : _firestore = firestore;

  Future<void> addDocument(String collection, Map<String, dynamic> data) async {
    await _firestore.collection(collection).add(data);
  }

  Future<void> updateDocument(String collection, String id, Map<String, dynamic> data) async {
    await _firestore.collection(collection).doc(id).update(data);
  }

  Future<void> deleteDocument(String collection, String documentId) async {
    await _firestore.collection(collection).doc(documentId).delete();
  }

  Future<DocumentSnapshot> getDocument(String collection, String documentId) async {
    return await _firestore.collection(collection).doc(documentId).get();
  }

  Future<DocumentSnapshot> getNestedDocument(
    String collection,
    String documentId,
    String subcollection,
    String subdocumentId,
  ) async {
    return await _firestore
        .collection(collection)
        .doc(documentId)
        .collection(subcollection)
        .doc(subdocumentId)
        .get();
  }

  DocumentReference getNestedDocumentReference(
    String collection,
    String documentId,
    String subcollection,
    String subdocumentId,
  ) {
    return _firestore
        .collection(collection)
        .doc(documentId)
        .collection(subcollection)
        .doc(subdocumentId);
  }

  Stream<List<T>> getCollectionStream<T>({
    required String collection,
    required T Function(Map<String, dynamic> data, String id) fromMap,
  }) {
    return _firestore
        .collection(collection)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => fromMap(doc.data(), doc.id))
            .toList());
  }

  DocumentReference getDocumentReference(String collection, String documentId) {
    return _firestore.collection(collection).doc(documentId);
  }

  FirebaseFirestore get firestore => _firestore;
} 