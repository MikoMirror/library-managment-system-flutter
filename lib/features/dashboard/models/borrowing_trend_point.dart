import 'package:cloud_firestore/cloud_firestore.dart';

class BorrowingTrendPoint {
  final DateTime timestamp;
  final int count;

  BorrowingTrendPoint({
    required this.timestamp,
    required this.count,
  });

  factory BorrowingTrendPoint.fromMap(Map<String, dynamic> map) {
    return BorrowingTrendPoint(
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      count: map['count'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp,
      'count': count,
    };
  }
} 