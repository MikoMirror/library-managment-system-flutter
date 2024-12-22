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
import 'features/reservation/bloc/reservation_bloc.dart';
import 'features/reservation/repositories/reservation_repository.dart';
import 'features/books/bloc/books_bloc.dart';
import 'features/users/bloc/users_bloc.dart';
import 'features/users/repositories/users_repository.dart';
import 'features/auth/screens/initial_admin_setup_screen.dart';
import 'core/theme/cubit/theme_cubit.dart';
import 'core/services/background/reservation_check_service.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final firestore = FirebaseFirestore.instance;
  final reservationsRepository = ReservationsRepository(firestore: firestore);
  
  // Start the reservation check service
  final reservationCheckService = ReservationCheckService(reservationsRepository);
  reservationCheckService.startChecking();

  final usersRepository = UsersRepository(
    firestore: FirebaseFirestore.instance,
  );

  final adminExists = await usersRepository.adminExists();

  runApp(MyApp(adminExists: adminExists));
}

class MyApp extends StatelessWidget {
  final bool adminExists;

  const MyApp({super.key, required this.adminExists});

  @override
  Widget build(BuildContext context) {
    
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => AuthBloc()..add(CheckAuthStatus()),
        ),
        BlocProvider(create: (context) => NavigationCubit()),
        BlocProvider(
          create: (context) => ReservationBloc(
            repository: ReservationsRepository(
              firestore: FirebaseFirestore.instance,
            ),
          ),
        ),
        RepositoryProvider<FirestoreService>(
          create: (context) => FirestoreService(),
        ),
        RepositoryProvider<BooksRepository>(
          create: (context) => BooksRepository(
            firestore: FirebaseFirestore.instance,
          ),
        ),
        BlocProvider(
          create: (context) => BooksBloc(
            repository: context.read<BooksRepository>(),
          ),
        ),
        RepositoryProvider<UsersRepository>(
          create: (context) => UsersRepository(
            firestore: FirebaseFirestore.instance,
          ),
        ),
        BlocProvider(
          create: (context) => UsersBloc(
            repository: context.read<UsersRepository>(),
          ),
        ),
        BlocProvider(create: (context) => ThemeCubit()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, state) {
          return MaterialApp(
            title: 'Library Management System',
            theme: AppTheme.getTheme(false),
            darkTheme: AppTheme.getTheme(true),
            themeMode: state.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: adminExists 
              ? NavigationHandler(
                  child: BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      if (state is AuthSuccess) {
                        return const HomeScreen();
                      }
                      return const LoginScreen();
                    },
                  ),
                )
              : BlocProvider(
                  create: (context) => NavigationCubit(),
                  child: const NavigationHandler(
                    child: InitialAdminSetupScreen(),
                  ),
                ),
          );
        },
      ),
    );
  }
}
