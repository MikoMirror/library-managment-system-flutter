import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'cubit/navigation_cubit.dart';
import 'cubit/navigation_state.dart';
import 'routes/route_names.dart';
import '../../features/books/screens/book_details_screen.dart';
import '../../features/books/cubit/rating/rating_cubit.dart';
import '../../features/auth/bloc/auth/auth_bloc.dart';
import '../../features/books/repositories/books_repository.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/home/screens/home_screen.dart';

class NavigationHandler extends StatelessWidget {
  final Widget child;

  const NavigationHandler({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return BlocListener<NavigationCubit, NavigationState>(
      listenWhen: (previous, current) => previous.route != current.route,
      listener: (context, navigationState) {
        switch (navigationState.route) {
          case RouteNames.home:
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                settings: const RouteSettings(name: RouteNames.home),
                builder: (context) => const HomeScreen(),
              ),
              (route) => false, // This removes all previous routes
            );
            break;
            
          case RouteNames.login:
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                settings: const RouteSettings(name: RouteNames.login),
                builder: (context) => const LoginScreen(),
              ),
              (route) => false,
            );
            break;
            
          case RouteNames.bookDetails:
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
            break;
          // Add other cases as needed
        }
      },
      child: child,
    );
  }
} 