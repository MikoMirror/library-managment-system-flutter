import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/bloc/auth/auth_bloc.dart';
import '../../auth/screens/login_screen.dart';
import '../../users/screens/users_screen.dart';
import '../../books/screens/books_screen.dart';
import '../../books/screens/book_details_screen.dart';
import '../../favorites/screens/favorites_screen.dart';
import '../../booking/screens/my_bookings_screen.dart';
import '../../booking/screens/bookings_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../../core/widgets/custom_navigation_bar.dart';
import '../../../core/navigation/cubit/navigation_cubit.dart';
import '../../../core/navigation/routes/route_names.dart';
import '../../users/models/user_model.dart';
import '../../books/bloc/books_bloc.dart';
import '../../books/repositories/books_repository.dart';
import '../../../core/navigation/cubit/navigation_state.dart';
import '../../booking/bloc/booking_bloc.dart';
import '../../booking/repositories/bookings_repository.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final _firestore = FirebaseFirestore.instance;
  UserModel? _cachedUserModel;
  List<NavigationItem>? _cachedNavigationItems;

  List<NavigationItem> _getNavigationItems(String role) {
    final commonItems = [
      const NavigationItem(
        index: 0,
        selectedIcon: Icons.book,
        unselectedIcon: Icons.book_outlined,
        label: 'Books',
      ),
      const NavigationItem(
        index: 3,
        selectedIcon: Icons.settings,
        unselectedIcon: Icons.settings_outlined,
        label: 'Settings',
      ),
    ];

    final middleItems = role == 'admin'
        ? [
            const NavigationItem(
              index: 1,
              selectedIcon: Icons.people,
              unselectedIcon: Icons.people_outline,
              label: 'Users',
            ),
            const NavigationItem(
              index: 2,
              selectedIcon: Icons.bookmark,
              unselectedIcon: Icons.bookmark_border,
              label: 'Bookings',
            ),
          ]
        : [
            const NavigationItem(
              index: 1,
              selectedIcon: Icons.favorite,
              unselectedIcon: Icons.favorite_border,
              label: 'Favorites',
            ),
            const NavigationItem(
              index: 2,
              selectedIcon: Icons.bookmark,
              unselectedIcon: Icons.bookmark_border,
              label: 'My Bookings',
            ),
          ];

    return [...commonItems.take(1), ...middleItems, ...commonItems.skip(1)];
  }

  Widget _getScreenForIndex(int index, String role) {
    final screens = role == 'admin'
        ? {
            0: () => BlocProvider(
                  create: (context) => BooksBloc(
                    repository: BooksRepository(firestore: _firestore),
                  ),
                  child: const BooksScreen(),
                ),
            1: () => const UsersScreen(),
            2: () => BlocProvider(
                  create: (context) => BookingBloc(
                    repository: BookingsRepository(firestore: _firestore),
                  )..add(LoadBookings()),
                  child: BookingsScreen(),
                ),
            3: () => const SettingsScreen(),
          }
        : {
            0: () => BlocProvider(
                  create: (context) => BooksBloc(
                    repository: BooksRepository(firestore: _firestore),
                  ),
                  child: const BooksScreen(),
                ),
            1: () => const FavoritesScreen(),
            2: () => BlocProvider(
                  create: (context) => BookingBloc(
                    repository: BookingsRepository(firestore: _firestore),
                  )..add(LoadBookings()),
                  child: MyBookingsScreen(),
                ),
            3: () => const SettingsScreen(),
          };

    return screens[index]?.call() ?? const Center(child: Text('Unknown Screen'));
  }

  void _onItemSelected(int index) {
    setState(() => _selectedIndex = index);
    
    if (_cachedUserModel == null) return;
    
    final navigationMap = {
      0: () => context.read<NavigationCubit>().navigateToBooks(),
      3: () => context.read<NavigationCubit>().navigateToSettings(),
    };

    if (_cachedUserModel!.role == 'admin') {
      navigationMap.addAll({
        1: () => context.read<NavigationCubit>().navigateToUsers(),
        2: () => context.read<NavigationCubit>().navigateToBookings(),
      });
    } else {
      navigationMap.addAll({
        1: () => context.read<NavigationCubit>().navigateToFavorites(),
        2: () => context.read<NavigationCubit>().navigateToMyBookings(),
      });
    }

    navigationMap[index]?.call();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<NavigationCubit, NavigationState>(
      listener: (context, state) {
        switch (state.route) {
          case RouteNames.books:
            setState(() => _selectedIndex = 0);
            break;
          case RouteNames.users:
          case RouteNames.favorites:
            setState(() => _selectedIndex = 1);
            break;
          case RouteNames.bookings:
          case RouteNames.myBookings:
            setState(() => _selectedIndex = 2);
            break;
          case RouteNames.settings:
            setState(() => _selectedIndex = 3);
            break;
          case RouteNames.bookDetails:
            final bookId = state.params?['bookId'] as String;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BookDetailsScreen(bookId: bookId),
              ),
            );
            break;
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is! AuthSuccess) {
            return const LoginScreen();
          }

          // Use cached data if available
          if (_cachedUserModel != null) {
            return _buildHomeContentWithUser(_cachedUserModel!);
          }

          return FutureBuilder<DocumentSnapshot>(
            future: _firestore.collection('users').doc(state.user.uid).get(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final userData = snapshot.data!.data() as Map<String, dynamic>;
              _cachedUserModel = UserModel.fromMap(userData);

              return _buildHomeContentWithUser(_cachedUserModel!);
            },
          );
        },
      ),
    );
  }

  Widget _buildHomeContentWithUser(UserModel userModel) {
    _cachedNavigationItems ??= _getNavigationItems(userModel.role);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(0),
        child: AppBar(
          backgroundColor: Colors.grey[100],
          elevation: 0,
          toolbarHeight: 0,
          automaticallyImplyLeading: false,
        ),
      ),
      body: _buildResponsiveLayout(userModel, _cachedNavigationItems!),
      bottomNavigationBar: isMobile ? CustomNavigationBar(
        selectedIndex: _selectedIndex,
        onItemSelected: _onItemSelected,
        isHorizontal: false,
        items: _cachedNavigationItems!,
      ) : null,
    );
  }

  Widget _buildResponsiveLayout(UserModel userModel, List<NavigationItem> navigationItems) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 600;
        
        return Row(
          children: [
            if (isDesktop)
              Container(
                width: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border(
                    right: BorderSide(
                      color: Colors.grey[200]!,
                      width: 1,
                    ),
                  ),
                ),
                child: CustomNavigationBar(
                  selectedIndex: _selectedIndex,
                  onItemSelected: _onItemSelected,
                  isHorizontal: true,
                  items: navigationItems,
                ),
              ),
            Expanded(
              child: _getScreenForIndex(_selectedIndex, userModel.role),
            ),
          ],
        );
      },
    );
  }
}