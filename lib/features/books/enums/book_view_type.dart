import 'package:flutter/material.dart';

enum BookViewType {
  desktop,
  mobile,
  table;

  String get label {
    switch (this) {
      case BookViewType.desktop:
        return 'Grid View';
      case BookViewType.mobile:
        return 'List View';
      case BookViewType.table:
        return 'Table View';
    }
  }

  IconData get icon {
    switch (this) {
      case BookViewType.desktop:
        return Icons.grid_view;
      case BookViewType.mobile:
        return Icons.view_list;
      case BookViewType.table:
        return Icons.table_rows;
    }
  }
} 