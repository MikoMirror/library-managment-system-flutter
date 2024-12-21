import 'package:flutter/material.dart';

class AppTheme {
  // Core UI Colors
  static CoreColors light = const CoreColors(
    // Main background colors
    background: Color(0xFFFAFAFA),      
    surface: Colors.white,              
    surfaceVariant: Color(0xFFF5F5F5), 
    
    // UI Element colors
    primary: Color(0xFF2196F3),        
    primaryContainer: Color(0xFF1976D2), 
    secondary: Color(0xFF64B5F6),      
    accent: Color(0xFFFF4081),          
    
    // Interactive elements
    selected: Color(0xFFE3F2FD),
    hover: Color(0xFFE8F5FF),
    pressed: Color(0xFFBBDEFB),
    
    // Text colors
    onBackground: Colors.black87,
    onSurface: Colors.black,
    onPrimary: Colors.white,
    onSecondary: Colors.black87,
    textSubtle: Colors.black54,
    
    // Status colors
    error: Color(0xFFB00020),
    success: Color(0xFF4CAF50),
    warning: Color(0xFFFFA000),
    info: Color(0xFF2196F3),
  );

  static CoreColors dark = const CoreColors(
    // Main background colors
    background: Color(0xFF121212),
    surface: Color(0xFF1E1E1E),
    surfaceVariant: Color(0xFF242424),
    
    // UI Element colors
    primary: Color(0xFF1976D2),
    primaryContainer: Color(0xFF2196F3),
    secondary: Color(0xFF64B5F6),
    accent: Color(0xFFF50057),
    
    // Interactive elements
    selected: Color(0xFF1E3954),
    hover: Color(0xFF233240),
    pressed: Color(0xFF0D47A1),
    
    // Text colors
    onBackground: Colors.white,
    onSurface: Colors.white,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    textSubtle: Colors.white70,
    
    // Status colors
    error: Color(0xFFCF6679),
    success: Color(0xFF81C784),
    warning: Color(0xFFFFB74D),
    info: Color(0xFF64B5F6),
  );

  static ReservationStatusColors reservationStatus = ReservationStatusColors(
    pending: light.warning,
    borrowed: light.success,
    returned: light.info,
    overdue: light.error,
    rejected: light.error,
    expired: light.textSubtle,
  );

  static ThemeData getTheme(bool isDarkMode) {
    final colors = isDarkMode ? dark : light;
    
    return ThemeData(
      useMaterial3: true,
      brightness: isDarkMode ? Brightness.dark : Brightness.light,
      
      scaffoldBackgroundColor: colors.background,
      canvasColor: colors.background,
      
      colorScheme: ColorScheme(
        brightness: isDarkMode ? Brightness.dark : Brightness.light,
        primary: colors.primary,
        secondary: colors.secondary,
        background: colors.background,
        surface: colors.surface,
        error: colors.error,
        onPrimary: colors.onPrimary,
        onSecondary: colors.onSecondary,
        onBackground: colors.onBackground,
        onSurface: colors.onSurface,
        onError: isDarkMode ? Colors.black : Colors.white,
      ),
      
      cardTheme: CardTheme(
        color: colors.surface,
        elevation: 2,
      ),
      
      appBarTheme: AppBarTheme(
        backgroundColor: colors.primary.withOpacity(0.1),
        foregroundColor: colors.primary,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: colors.onBackground,
        ),
      ),
      
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.primary.withOpacity(0.1),
        indicatorColor: colors.selected,
        labelTextStyle: MaterialStateProperty.all(
          TextStyle(color: colors.primary),
        ),
        iconTheme: MaterialStateProperty.all(
          IconThemeData(color: colors.primary),
        ),
      ),
      
      drawerTheme: DrawerThemeData(
        backgroundColor: colors.background,
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
        ),
      ),
    );
  }
}

class CoreColors {
  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color primary;
  final Color primaryContainer;
  final Color secondary;
  final Color accent;
  final Color selected;
  final Color hover;
  final Color pressed;
  final Color onBackground;
  final Color onSurface;
  final Color onPrimary;
  final Color onSecondary;
  final Color textSubtle;
  final Color error;
  final Color success;
  final Color warning;
  final Color info;

  const CoreColors({
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.primary,
    required this.primaryContainer,
    required this.secondary,
    required this.accent,
    required this.selected,
    required this.hover,
    required this.pressed,
    required this.onBackground,
    required this.onSurface,
    required this.onPrimary,
    required this.onSecondary,
    required this.textSubtle,
    required this.error,
    required this.success,
    required this.warning,
    required this.info,
  });
}

class ReservationStatusColors {
  final Color pending;
  final Color borrowed;
  final Color returned;
  final Color overdue;
  final Color rejected;
  final Color expired;

  const ReservationStatusColors({
    required this.pending,
    required this.borrowed,
    required this.returned,
    required this.overdue,
    required this.rejected,
    required this.expired,
  });
}

