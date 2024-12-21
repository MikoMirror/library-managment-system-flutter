import 'package:flutter_bloc/flutter_bloc.dart';
import '../routes/route_names.dart';
import 'navigation_state.dart';

class NavigationCubit extends Cubit<NavigationState> {
  NavigationCubit() : super(const NavigationState(route: RouteNames.home));

  // Basic navigation methods
  void navigateToHome() => _navigate(RouteNames.home);
  void navigateToBooks() => _navigate(RouteNames.books);
  void navigateToUsers() => _navigate(RouteNames.users);
  void navigateToFavorites() => _navigate(RouteNames.favorites);
  void navigateToBookings() => _navigate(RouteNames.bookings);
  void navigateToSettings() => _navigate(RouteNames.settings);
  void navigateToLogin() => _navigate(RouteNames.login);
  void navigateToInitialSetup() => _navigate(RouteNames.initialSetup);
  void navigateToAddUser() => _navigate(RouteNames.addUser);
  void navigateToDashboard() => _navigate(RouteNames.dashboard);
  
  // Navigation with parameters
  void navigateToBookDetails(String bookId) => _navigate(
    RouteNames.bookDetails,
    {'bookId': bookId},
  );

  void navigateToEditBook(String bookId) => _navigate(
    RouteNames.editBook,
    {'bookId': bookId},
  );

  // Private helper method for navigation
  void _navigate(String route, [Map<String, dynamic>? params]) {
    emit(NavigationState(route: route, params: params));
  }
} 