import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/repositories/base_repository.dart';

class FavoritesRepository implements BaseRepository {
  final FirebaseFirestore _firestore;

  FavoritesRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<bool> isBookFavorited(String userId, String bookId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(bookId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  Future<void> toggleFavorite(String userId, String bookId) async {
    final userFavRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(bookId);

    final doc = await userFavRef.get();
    if (doc.exists) {
      await userFavRef.delete();
    } else {
      await userFavRef.set({
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Stream<List<String>> getUserFavoriteIds(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
  }

  Stream<List<QueryDocumentSnapshot>> getFavoriteBooks(List<String> bookIds) {
    if (bookIds.isEmpty) return Stream.value([]);
    
    return _firestore
        .collection('books')
        .where(FieldPath.documentId, whereIn: bookIds)
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  @override
  void dispose() {
    // Clean up any resources if needed
  }
} 