import 'package:flutter/material.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/initial_admin_setup_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/users/screens/users_screen.dart';
import '../../features/users/screens/add_user_screen.dart';
import '../services/auth/admin_check_service.dart';
import 'route_names.dart';

class AppRouter {
  static final _adminCheckService = AdminCheckService();

  static Map<String, Widget Function(BuildContext)> get routes => {
        RouteNames.initial: (context) => FutureBuilder<bool>(
              future: _adminCheckService.hasAdminUser(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasData && !snapshot.data!) {
                  return const InitialAdminSetupScreen();
                }

                return const LoginScreen();
              },
            ),
        RouteNames.login: (context) => const LoginScreen(),
        RouteNames.home: (context) => const HomeScreen(),
        RouteNames.users: (context) => const UsersScreen(),
        RouteNames.addUser: (context) => const AddUserScreen(),
      };

  static Route<dynamic> onUnknownRoute(RouteSettings settings) {
    return MaterialPageRoute(
      builder: (context) => Scaffold(
        body: Center(
          child: Text('Route ${settings.name} not found'),
        ),
      ),
    );
  }
} 