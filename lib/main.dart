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
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/cubit/test_mode_cubit.dart';

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    final firestore = FirebaseFirestore.instance;
    final reservationsRepository = ReservationsRepository(firestore: firestore);
    final usersRepository = UsersRepository(firestore: firestore);
    final prefs = await SharedPreferences.getInstance();
    final adminExists = await usersRepository.adminExists();

    runApp(
      MultiProvider(
        providers: [
          Provider<SharedPreferences>.value(value: prefs),
          Provider<ReservationsRepository>(
            create: (_) => reservationsRepository,
          ),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (context) => AuthBloc()..add(CheckAuthStatus()),
            ),
            BlocProvider(create: (context) => NavigationCubit()),
            BlocProvider(
              create: (context) => ReservationBloc(
                repository: context.read<ReservationsRepository>(),
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
            BlocProvider(
              create: (_) => ThemeCubit(),
            ),
            BlocProvider<TestModeCubit>(
              create: (context) => TestModeCubit(
                context.read<SharedPreferences>(),
              ),
            ),
          ],
          child: MyApp(adminExists: adminExists),
        ),
      ),
    );
  }, (error, stack) {
    print('Error in runZonedGuarded: $error\n$stack');
  });
}

class MyApp extends StatefulWidget {
  final bool adminExists;

  const MyApp({super.key, required this.adminExists});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late ReservationsRepository _reservationsRepository;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _reservationsRepository = context.read<ReservationsRepository>();
    _reservationsRepository.startPeriodicCheck();
  }

  @override
  void dispose() {
    _reservationsRepository.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

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
            repository: context.read<ReservationsRepository>(),
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
        BlocProvider(
          create: (_) => ThemeCubit(),
        ),
        BlocProvider<TestModeCubit>(
          create: (context) => TestModeCubit(
            context.read<SharedPreferences>(),
          ),
        ),
      ],
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, state) {
          return MaterialApp(
            title: 'Library Management System',
            theme: AppTheme.getTheme(false),
            darkTheme: AppTheme.getTheme(true),
            themeMode: state.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: widget.adminExists 
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
