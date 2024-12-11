import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../../../core/repositories/base_repository.dart';

class UsersRepository implements BaseRepository {
  final FirebaseFirestore _firestore;

  UsersRepository({required FirebaseFirestore firestore}) : _firestore = firestore;

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

  @override
  void dispose() {
    // Clean up any resources if needed
  }
} 