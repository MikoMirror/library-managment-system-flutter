class RouteNames {
  // Private constructor to prevent instantiation
  const RouteNames._();

  // Main routes
  static const String home = '/';
  static const String login = '/login';
  
  // Book related routes
  static const String books = '/books';
  static const String bookDetails = '/books/details';
  static const String editBook = '/books/edit';
  
  // User related routes
  static const String users = '/users';
  static const String addUser = '/add-user';
  static const String favorites = '/favorites';
  
  // Booking related routes
  static const String bookings = '/bookings';
  
  // Settings
  static const String settings = '/settings';
  
  // Admin routes
  static const String initialSetup = '/initial-setup';
}