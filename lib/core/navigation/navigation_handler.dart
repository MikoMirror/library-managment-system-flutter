import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'routes/route_names.dart';
import '../../features/auth/bloc/auth/auth_bloc.dart';
import '../../features/auth/screens/login_screen.dart';


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