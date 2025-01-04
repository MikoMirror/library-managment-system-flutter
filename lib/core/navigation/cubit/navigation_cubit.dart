import 'package:flutter_bloc/flutter_bloc.dart';
import '../routes/route_names.dart';
import 'navigation_state.dart';
import '../../../features/books/enums/sort_type.dart';

class NavigationCubit extends Cubit<NavigationState> {
  final List<NavigationState> _navigationStack = [];

  NavigationCubit() : super(const NavigationState(route: RouteNames.home)) {
    _navigationStack.add(state);
  }

  // Basic navigation methods
  void navigateToHome({bool showBooks = false}) {
    emit(NavigationState(
      route: RouteNames.home,
      params: showBooks ? {'showBooks': true} : null,
    ));
  }
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

  void navigateToSortedBooks(SortType sortType) {
    emit(NavigationState(
      route: RouteNames.home,
      params: {
        'showBooks': true,
        'sortType': sortType.toString(),
      },
    ));
  }

  void navigateToBooks(SortType sortType) {
    // Instead of navigating to a new route, update the home state with parameters
    emit(NavigationState(
      route: RouteNames.home,
      params: {
        'showBooks': true,
        'sortType': sortType.toString(),
      },
    ));
  }

  void goBack() {
    if (_navigationStack.length > 1) {
      _navigationStack.removeLast();
      final previousState = _navigationStack.last;
      emit(previousState);
    }
  }

  bool canGoBack() => _navigationStack.length > 1;

  // Private helper method for navigation
  void _navigate(String route, [Map<String, dynamic>? params]) {
    emit(NavigationState(route: route, params: params));
  }
} 