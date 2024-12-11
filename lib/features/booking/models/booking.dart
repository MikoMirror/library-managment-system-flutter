import 'package:cloud_firestore/cloud_firestore.dart';

class Booking {
  final String? id;
  final String userId;
  final String bookId;
  final String status;
  final Timestamp borrowedDate;
  final Timestamp dueDate;
  final int quantity;
  final String? bookTitle;
  final String? userName;
  final String? userLibraryNumber;

  Booking({
    this.id,
    required this.userId,
    required this.bookId,
    required this.status,
    required this.borrowedDate,
    required this.dueDate,
    required this.quantity,
    this.bookTitle,
    this.userName,
    this.userLibraryNumber,
  });

  String get formattedBorrowedDate {
    return _formatDate(borrowedDate.toDate());
  }

  String get formattedDueDate {
    return _formatDate(dueDate.toDate());
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  bool get isOverdue {
    final now = DateTime.now();
    return dueDate.toDate().isBefore(now) && status != 'returned';
  }

  factory Booking.fromMap(Map<String, dynamic> map, String? id) {
    return Booking(
      id: id,
      userId: map['userId'],
      bookId: map['bookId'],
      status: map['status'],
      borrowedDate: map['borrowedDate'],
      dueDate: map['dueDate'],
      quantity: map['quantity'],
      bookTitle: map['bookTitle'],
      userName: map['userName'],
      userLibraryNumber: map['userLibraryNumber'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'bookId': bookId,
      'status': status,
      'borrowedDate': borrowedDate,
      'dueDate': dueDate,
      'quantity': quantity,
      'bookTitle': bookTitle,
      'userName': userName,
      'userLibraryNumber': userLibraryNumber,
    };
  }

  Booking copyWith({
    String? id,
    String? userId,
    String? bookId,
    String? status,
    Timestamp? borrowedDate,
    Timestamp? dueDate,
    int? quantity,
    String? bookTitle,
    String? userName,
    String? userLibraryNumber,
  }) {
    return Booking(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      bookId: bookId ?? this.bookId,
      status: status ?? this.status,
      borrowedDate: borrowedDate ?? this.borrowedDate,
      dueDate: dueDate ?? this.dueDate,
      quantity: quantity ?? this.quantity,
      bookTitle: bookTitle ?? this.bookTitle,
      userName: userName ?? this.userName,
      userLibraryNumber: userLibraryNumber ?? this.userLibraryNumber,
    );
  }
} 