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
import '../../features/users/screens/add_user_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/auth/screens/initial_admin_setup_screen.dart';


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
      listener: (context, navigationState) async {
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

          case RouteNames.addUser:
            final authState = context.read<AuthBloc>().state;
            if (authState is AuthSuccess) {
              final userDoc = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(authState.user.uid)
                  .get();
              final userData = userDoc.data() as Map<String, dynamic>;
              final isCurrentUserAdmin = userData['role'] == 'admin';

              if (!context.mounted) return;
              
              if (isCurrentUserAdmin) {
                debugPrint('Navigating to AddUserScreen');
                Navigator.of(context).push(
                  MaterialPageRoute(
                    settings: const RouteSettings(name: RouteNames.addUser),
                    builder: (context) => const AddUserScreen(isAdmin: false),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Only administrators can add new users'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
            break;

          case RouteNames.initialSetup:
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                settings: const RouteSettings(name: RouteNames.initialSetup),
                builder: (context) => const InitialAdminSetupScreen(),
              ),
              (route) => false,
            );
            break;

          // Add other cases as needed
        }
      },
      child: child,
    );
  }
} 