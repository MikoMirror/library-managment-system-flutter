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
    _navigate(NavigationState(
      route: RouteNames.home,
      params: showBooks ? {'showBooks': true} : null,
    ));
  }
  void navigateToUsers() => _navigate(NavigationState(route: RouteNames.users));
  void navigateToFavorites() => _navigate(NavigationState(route: RouteNames.favorites));
  void navigateToBookings() => _navigate(NavigationState(route: RouteNames.bookings));
  void navigateToSettings() => _navigate(NavigationState(route: RouteNames.settings));
  void navigateToLogin() => _navigate(NavigationState(route: RouteNames.login));
  void navigateToInitialSetup() => _navigate(NavigationState(route: RouteNames.initialSetup));
  void navigateToAddUser() => _navigate(NavigationState(route: RouteNames.addUser));
  void navigateToDashboard() => _navigate(NavigationState(route: RouteNames.dashboard));
  
  // Navigation with parameters
  void navigateToBookDetails(String bookId) {
    final currentRoute = state.route;
    print('Navigating from: $currentRoute to book details'); // Debug

    _navigate(NavigationState(
      route: RouteNames.bookDetails,
      params: {
        'bookId': bookId,
        'previousRoute': currentRoute, // Already stores previous route
      },
    ));
  }

  void navigateToEditBook(String bookId) => _navigate(
    NavigationState(
      route: RouteNames.editBook,
      params: {'bookId': bookId},
    ),
  );

  void navigateToSortedBooks(SortType sortType) {
    _navigate(NavigationState(
      route: RouteNames.home,
      params: {
        'showBooks': true,
        'sortType': sortType.toString(),
      },
    ));
  }

  void navigateToBooks(SortType sortType) {
    _navigate(NavigationState(
      route: RouteNames.books,
      params: {'sortType': sortType.toString()},
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
  void _navigate(NavigationState newState) {
    _navigationStack.add(newState);
    emit(newState);
  }

  // Helper method to get the previous route
  String? getPreviousRoute() {
    if (_navigationStack.length > 1) {
      return _navigationStack[_navigationStack.length - 2].route;
    }
    return null;
  }
} 