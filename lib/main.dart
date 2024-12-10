import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'firebase_options.dart';
import 'features/auth/bloc/auth/auth_bloc.dart';
import 'core/theme/app_theme.dart';
import 'features/home/screens/home_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'core/navigation/cubit/navigation_cubit.dart';
import 'core/navigation/navigation_handler.dart';
import 'features/books/repositories/books_repository.dart';
import 'core/services/database/firestore_service.dart';
import 'core/services/auth/admin_check_service.dart';
import 'features/auth/screens/initial_admin_setup_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => AuthBloc()..add(CheckAuthStatus()),
        ),
        BlocProvider(create: (context) => NavigationCubit()),
        RepositoryProvider<FirestoreService>(
          create: (context) => FirestoreService(),
        ),
        RepositoryProvider<BooksRepository>(
          create: (context) => BooksRepository(
            firestore: FirebaseFirestore.instance,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Library Management System',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: FutureBuilder<bool>(
          future: AdminCheckService().hasAdminUser(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.data == false) {
              return const NavigationHandler(
                child: InitialAdminSetupScreen(),
              );
            }

            return BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                if (state is AuthInitial || state is AuthLoading) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                if (state is AuthSuccess) {
                  return const NavigationHandler(
                    child: HomeScreen(),
                  );
                }

                return const LoginScreen();
              },
            );
          },
        ),
      ),
    );
  }
}
