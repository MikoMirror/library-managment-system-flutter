class BookingConstants {
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;
  static const double wideDesktopBreakpoint = 1800;
  
  static const Duration checkInterval = Duration(hours: 2);
  static const Duration reservationExpiryTime = Duration(hours: 24);
  static const Duration defaultLoanPeriod = Duration(days: 14);
  
  static const Map<String, String> statusDisplayNames = {
    'reserved': 'Reserved',
    'borrowed': 'Borrowed',
    'returned': 'Returned',
    'overdue': 'Overdue',
    'expired': 'Expired',
    'canceled': 'Canceled',
  };
} 