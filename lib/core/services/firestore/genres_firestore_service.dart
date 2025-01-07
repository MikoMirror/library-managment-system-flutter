import 'package:cloud_firestore/cloud_firestore.dart';
import 'base_firestore_service.dart';
import '../../../features/books/models/genre.dart';

class GenresFirestoreService extends BaseFirestoreService {
  static const String collectionPath = 'genres';

  Stream<List<Genre>> getGenresStream() {
    return getCollectionStream(
      collection: collectionPath,
      fromMap: Genre.fromMap,
    ).map((list) => list ?? []);
  }

  Future<void> addGenre(String name) async {
    final id = name.toLowerCase().replaceAll(' ', '_');
    await firestore.collection(collectionPath).doc(id).set({
      'name': name,
      'isDefault': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeGenre(String genreId) async {
    final doc = await firestore.collection(collectionPath).doc(genreId).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['isDefault'] == true) {
        throw Exception('Cannot remove default genre');
      }
      await firestore.collection(collectionPath).doc(genreId).delete();
    }
  }

  Future<void> initializeDefaultGenres() async {
    final defaultGenres = [
      {'id': 'fiction', 'name': 'Fiction', 'isDefault': true},
      {'id': 'non_fiction', 'name': 'Non-Fiction', 'isDefault': true},
      {'id': 'mystery', 'name': 'Mystery', 'isDefault': true},
      {'id': 'science_fiction', 'name': 'Science Fiction', 'isDefault': true},

    ];

    final batch = firestore.batch();
    for (final genre in defaultGenres) {
      final doc = firestore.collection(collectionPath).doc(genre['id'] as String);
      final exists = await doc.get();
      if (!exists.exists) {
        batch.set(doc, genre);
      }
    }
    await batch.commit();
  }
} 