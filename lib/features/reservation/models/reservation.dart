import 'package:cloud_firestore/cloud_firestore.dart';

class Reservation {
  final String? id;
  final String userId;
  final String bookId;
  final String status;
  final Timestamp borrowedDate;
  final Timestamp dueDate;
  final Timestamp? returnedDate;
  final int quantity;
  final String bookTitle;
  final String? userName;
  final String? userLibraryNumber;

  Reservation({
    this.id,
    required this.userId,
    required this.bookId,
    required this.status,
    required this.borrowedDate,
    required this.dueDate,
    this.returnedDate,
    required this.quantity,
    required this.bookTitle,
    this.userName,
    this.userLibraryNumber,
  });

  Timestamp get displayDate {
    return status == 'returned' && returnedDate != null 
        ? returnedDate! 
        : dueDate;
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

  String get currentStatus {
    if (status == 'expired') return 'expired';
    if (status != 'returned' && isOverdue) return 'overdue';
    return status;
  }

  bool get isOverdue {
    if (status == 'returned' || status == 'expired') return false;
    final now = DateTime.now();
    return dueDate.toDate().isBefore(now);
  }

  factory Reservation.fromMap(Map<String, dynamic> map, String id) {
    return Reservation(
      id: id,
      userId: map['userId'],
      bookId: map['bookId'],
      status: map['status'],
      borrowedDate: map['borrowedDate'],
      dueDate: map['dueDate'],
      returnedDate: map['returnedDate'],
      quantity: map['quantity'],
      bookTitle: map['bookTitle'] ?? 'Unknown',
      userName: map['userName'] ?? 'Unknown',
      userLibraryNumber: map['userLibraryNumber'] ?? 'N/A',
    );
  }

  Map<String, dynamic> toMap() {
    final currentBookingStatus = currentStatus;
    return {
      'userId': userId,
      'bookId': bookId,
      'status': currentBookingStatus,
      'borrowedDate': borrowedDate,
      'dueDate': dueDate,
      'quantity': quantity,
      'bookTitle': bookTitle,
      'userName': userName,
      'userLibraryNumber': userLibraryNumber,
      'displayDate': displayDate,
    };
  }

  Reservation copyWith({
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
    Timestamp? displayDate,
  }) {
    return Reservation(
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