import 'package:flutter/material.dart';

class BookCardStyles {
  static const desktopTitleStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static const desktopAuthorStyle = TextStyle(
    fontSize: 14,
    color: Colors.white70,
  );

  static const mobileTitleStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );

  static TextStyle mobileAuthorStyle(BuildContext context) => TextStyle(
    fontSize: 14,
    color: Colors.grey[600],
  );
} 