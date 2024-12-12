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
import 'features/booking/bloc/booking_bloc.dart';
import 'features/booking/repositories/bookings_repository.dart';
import 'features/books/bloc/books_bloc.dart';
import 'features/users/bloc/users_bloc.dart';
import 'features/users/repositories/users_repository.dart';


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
        BlocProvider(
          create: (context) => BookingBloc(
            repository: BookingsRepository(
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
      ],
      child: MaterialApp(
        title: 'Library Management System',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: NavigationHandler(
          child: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is AuthSuccess) {
                return const HomeScreen();
              }
              return const LoginScreen();
            },
          ),
        ),
      ),
    );
  }
}
