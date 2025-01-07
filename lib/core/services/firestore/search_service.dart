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
    
    // Apply additional filters if any
    if (additionalFilters != null) {
      additionalFilters.forEach((field, value) {
        baseQuery = baseQuery.where(field, isEqualTo: value);
      });
    }

    // If no specific search fields are provided, use searchTerms array
    if (searchFields.isEmpty) {
      return baseQuery
          .where('searchTerms', arrayContains: query)
          .snapshots();
    }

    // Use the first search field for the query
    // This could be enhanced to support multiple fields
    return baseQuery
        .where(searchFields.first, isGreaterThanOrEqualTo: query)
        .where(searchFields.first, isLessThanOrEqualTo: '$query\uf8ff')
        .snapshots();
  }
} 