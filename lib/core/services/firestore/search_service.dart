import 'package:cloud_firestore/cloud_firestore.dart';

class SearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> search({
    required String collection,
    required String query,
    List<String> searchFields = const [],
    Map<String, dynamic>? additionalFilters,
  }) {
    query = query.toLowerCase();
    
    Query baseQuery = _firestore.collection(collection);
    
    // Apply additional filters if provided
    if (additionalFilters != null) {
      additionalFilters.forEach((field, value) {
        baseQuery = baseQuery.where(field, isEqualTo: value);
      });
    }

    // If using searchTerms array
    if (searchFields.isEmpty) {
      return baseQuery
          .where('searchTerms', arrayContains: query)
          .snapshots();
    }

    // If using individual fields
    return baseQuery.where(searchFields.first, isGreaterThanOrEqualTo: query)
        .where(searchFields.first, isLessThanOrEqualTo: query + '\uf8ff')
        .snapshots();
  }
} 