import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'cubit/navigation_cubit.dart';
import 'cubit/navigation_state.dart';
import 'routes/route_names.dart';
import '../../features/books/screens/book_details_screen.dart';
import '../../features/books/cubit/rating/rating_cubit.dart';
import '../../features/auth/bloc/auth/auth_bloc.dart';
import '../../features/books/repositories/books_repository.dart';

class NavigationHandler extends StatelessWidget {
  final Widget child;

  const NavigationHandler({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return BlocListener<NavigationCubit, NavigationState>(
      listenWhen: (previous, current) {
        // Get all routes in the navigator
        final navigator = Navigator.of(context);
        final routes = navigator.widget.pages ?? [];
        final currentRoute = ModalRoute.of(context)?.settings.name;

        // Check if we're already navigating to this route with the same parameters
        bool isDuplicate = routes.any((route) {
          return route.name == RouteNames.bookDetails &&
                 (route.arguments as Map<String, dynamic>?)?['bookId'] == 
                 current.params?['bookId'];
        });

        // Only navigate if it's a new route or new book ID and not already on that route
        return (previous.route != current.route || 
               previous.params?['bookId'] != current.params?['bookId']) &&
               currentRoute != current.route &&
               !isDuplicate;
      },
      listener: (context, navigationState) {
        if (navigationState.route == RouteNames.bookDetails) {
          // Remove any existing book details screens from the stack
          Navigator.of(context).popUntil(
            (route) => route.settings.name != RouteNames.bookDetails
          );

          // Push the new book details screen
          Navigator.of(context).push(
            MaterialPageRoute(
              settings: RouteSettings(
                name: RouteNames.bookDetails,
                arguments: navigationState.params,
              ),
              builder: (context) => MultiBlocProvider(
                providers: [
                  BlocProvider<RatingCubit>(
                    create: (context) => RatingCubit(
                      bookId: navigationState.params?['bookId'],
                      userId: (context.read<AuthBloc>().state as AuthSuccess).user.uid,
                      repository: context.read<BooksRepository>(),
                    ),
                  ),
                ],
                child: BookDetailsScreen(
                  bookId: navigationState.params?['bookId'],
                ),
              ),
            ),
          );
        }
      },
      child: child,
    );
  }
} 