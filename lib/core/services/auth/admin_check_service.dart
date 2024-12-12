import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

class AdminCheckService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _logger = Logger();

  Future<bool> hasAdminUser() async {
    try {
      final QuerySnapshot query = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .limit(1)
          .get();
      
      return query.docs.isNotEmpty;
    } catch (e) {
      _logger.e('Error checking for admin:', error: e);
      return false;
    }
  }
} 