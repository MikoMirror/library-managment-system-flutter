import 'package:cloud_firestore/cloud_firestore.dart';

class AdminCheckService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> hasAdminUser() async {
    try {
      final QuerySnapshot query = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .limit(1)
          .get();
      
      return query.docs.isNotEmpty;
    } catch (e) {
      print('Error checking for admin: $e');
      return false;
    }
  }
} 