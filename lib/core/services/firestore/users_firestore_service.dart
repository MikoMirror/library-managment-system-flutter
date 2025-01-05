import 'package:cloud_firestore/cloud_firestore.dart';
import 'base_firestore_service.dart';
import '../../../features/users/models/user_model.dart';

class UsersFirestoreService extends BaseFirestoreService {
  static const String collectionPath = 'users';

  Future<void> createUser(UserModel user) async {
    await firestore
        .collection(collectionPath)
        .doc(user.userId)
        .set(user.toMap());
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> getUserStream(String userId) {
    return firestore
        .collection(collectionPath)
        .doc(userId)
        .snapshots();
  }

  Stream<List<UserModel>> getUsersStream() {
    return getCollectionStream<UserModel>(
      collection: collectionPath,
      fromMap: (data, id) => UserModel.fromMap({...data, 'userId': id}),
    );
  }

  Future<List<UserModel>> searchUsers(String query) async {
    query = query.toLowerCase();
    final querySnapshot = await firestore
        .collection(collectionPath)
        .where('searchTerms', arrayContains: query)
        .get();

    return querySnapshot.docs
        .map((doc) => UserModel.fromMap({...doc.data(), 'userId': doc.id}))
        .toList();
  }

  Future<bool> checkUserExists(String email) async {
    final querySnapshot = await firestore
        .collection(collectionPath)
        .where('email', isEqualTo: email)
        .get();
    return querySnapshot.docs.isNotEmpty;
  }

  Future<UserModel?> getUserById(String userId) async {
    final doc = await getDocument(collectionPath, userId);
    if (!doc.exists) return null;
    return UserModel.fromMap({
      ...doc.data() as Map<String, dynamic>,
      'userId': doc.id
    });
  }

  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    await updateDocument(collectionPath, userId, data);
  }

  @override
  DocumentReference<Map<String, dynamic>> getDocumentReference(String collection, String documentId) {
    return firestore.collection(collection).doc(documentId);
  }

  
} 