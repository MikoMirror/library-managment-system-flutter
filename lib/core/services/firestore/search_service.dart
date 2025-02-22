import 'package:cloud_firestore/cloud_firestore.dart';

class SearchService {
  final FirebaseFirestore _firestore;

  SearchService({FirebaseFirestore? firestore}) 
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<QuerySnapshot> search({
    required String collection,
    required String query,
    List<String> searchFields = const [],
    Map<String, dynamic>? additionalFilters,
  }) {
    query = query.toLowerCase();
    
    Query baseQuery = _firestore.collection(collection);

    if (additionalFilters != null) {
      additionalFilters.forEach((field, value) {
        baseQuery = baseQuery.where(field, isEqualTo: value);
      });
    }

  
    if (searchFields.isEmpty) {
      return baseQuery
          .where('searchTerms', arrayContains: query)
          .snapshots();
    }

    return baseQuery
        .where(searchFields.first, isGreaterThanOrEqualTo: query)
        .where(searchFields.first, isLessThanOrEqualTo: '$query\uf8ff')
        .snapshots();
  }
} 