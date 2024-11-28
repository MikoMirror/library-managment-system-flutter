import 'package:cloud_firestore/cloud_firestore.dart';

class Booking {
  final String? id;
  final String userId;
  final String bookId;
  final String status;
  final Timestamp borrowedDate;
  final Timestamp dueDate;

  Booking({
    this.id,
    required this.userId,
    required this.bookId,
    required this.status,
    required this.borrowedDate,
    required this.dueDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'bookId': bookId,
      'status': status,
      'borrowedDate': borrowedDate,
      'dueDate': dueDate,
    };
  }

  factory Booking.fromMap(Map<String, dynamic> map, String documentId) {
    return Booking(
      id: documentId,
      userId: map['userId'],
      bookId: map['bookId'],
      status: map['status'],
      borrowedDate: map['borrowedDate'],
      dueDate: map['dueDate'],
    );
  }
} 