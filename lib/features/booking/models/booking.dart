import 'package:cloud_firestore/cloud_firestore.dart';

class Booking {
  final String? id;
  final String userId;
  final String bookId;
  final String status;
  final Timestamp borrowedDate;
  final Timestamp dueDate;
  final int quantity;
  final Timestamp createdAt;
  final Timestamp updatedAt;
  String? bookTitle; 
  String? userName;  

  Booking({
    this.id,
    required this.userId,
    required this.bookId,
    required this.status,
    required this.borrowedDate,
    required this.dueDate,
    required this.quantity,
    required this.createdAt,
    required this.updatedAt,
    this.bookTitle,
    this.userName,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'bookId': bookId,
      'status': status,
      'borrowedDate': borrowedDate,
      'dueDate': dueDate,
      'quantity': quantity,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory Booking.fromMap(Map<String, dynamic> map, String documentId) {
    return Booking(
      id: documentId,
      userId: map['userId'] ?? '',
      bookId: map['bookId'] ?? '',
      status: map['status'] ?? 'pending',
      borrowedDate: map['borrowedDate'] ?? Timestamp.now(),
      dueDate: map['dueDate'] ?? Timestamp.now(),
      quantity: map['quantity'] ?? 1,
      createdAt: map['createdAt'] ?? Timestamp.now(),
      updatedAt: map['updatedAt'] ?? Timestamp.now(),
    );
  }

  Booking copyWith({
    String? id,
    String? userId,
    String? bookId,
    String? status,
    Timestamp? borrowedDate,
    Timestamp? dueDate,
    int? quantity,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    String? bookTitle,
    String? userName,
  }) {
    return Booking(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      bookId: bookId ?? this.bookId,
      status: status ?? this.status,
      borrowedDate: borrowedDate ?? this.borrowedDate,
      dueDate: dueDate ?? this.dueDate,
      quantity: quantity ?? this.quantity,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      bookTitle: bookTitle ?? this.bookTitle,
      userName: userName ?? this.userName,
    );
  }

  bool get isOverdue {
    return dueDate.toDate().isBefore(DateTime.now()) && status != 'returned';
  }

  String get formattedBorrowedDate {
    return _formatDate(borrowedDate.toDate());
  }

  String get formattedDueDate {
    return _formatDate(dueDate.toDate());
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
} 