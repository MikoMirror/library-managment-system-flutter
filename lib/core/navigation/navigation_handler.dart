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
import '../../features/books/enums/sort_type.dart';
import '../../features/books/screens/books_screen.dart';
import '../../features/books/bloc/books_bloc.dart';


class NavigationHandler extends StatelessWidget {
  final Widget child;

  const NavigationHandler({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthInitial) {
          // Check if we were previously logged in
          final previousState = context.read<AuthBloc>().state;
          final wasLoggedIn = previousState is AuthSuccess;
          
          if (wasLoggedIn) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Your session has expired. Please log in again.'),
                backgroundColor: Colors.red,
              ),
            );
            
            // Navigate to login
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                settings: const RouteSettings(name: RouteNames.login),
                builder: (context) => const LoginScreen(),
              ),
              (route) => false,
            );
          }
        }
      },
      child: child,
    );
  }
} 