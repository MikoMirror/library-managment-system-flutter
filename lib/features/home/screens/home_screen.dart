import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/bloc/auth/auth_bloc.dart';
import '../../auth/screens/login_screen.dart';
import '../../users/screens/users_screen.dart';
import '../../books/screens/books_screen.dart';
import '../../books/screens/book_details_screen.dart';
import '../../favorites/screens/favorites_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../../core/widgets/custom_navigation_bar.dart';
import '../../../core/navigation/cubit/navigation_cubit.dart';
import '../../../core/navigation/routes/route_names.dart';
import '../../users/models/user_model.dart';
import '../../books/bloc/books_bloc.dart';
import '../../books/repositories/books_repository.dart';
import '../../../core/navigation/cubit/navigation_state.dart';
import '../../reservation/bloc/reservation_bloc.dart';
import '../../reservation/repositories/reservation_repository.dart';
import '../../reservation/screens/reservations_screen.dart';
import '../../dashboard/cubit/dashboard_cubit.dart';
import '../../../core/services/firestore/books_firestore_service.dart';
import 'dart:async';
import '../../../core/services/firestore/users_firestore_service.dart';
import '../../../core/services/firestore/reservations_firestore_service.dart';
import '../screens/main_home_screen.dart';
import '../../books/enums/sort_type.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../../books/bloc/books_event.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  UserModel? _cachedUserModel;
  List<NavigationItem>? _cachedNavigationItems;
  late final DashboardCubit _dashboardCubit;
  late final BooksBloc _booksBloc;
  late final ReservationBloc _reservationBloc;
  Stream<DocumentSnapshot>? _adminCheckStream;
  bool _isSmallScreen = false;
  bool _isPortrait = false;
  late final BooksFirestoreService _firestoreService;
  late final UsersFirestoreService _usersService;
  late final ReservationsFirestoreService _reservationsService;

  @override
  void initState() {
    super.initState();
    _firestoreService = BooksFirestoreService();
    _usersService = context.read<UsersFirestoreService>();
    _reservationsService = context.read<ReservationsFirestoreService>();
    
    _dashboardCubit = DashboardCubit(_firestoreService);
    _booksBloc = BooksBloc(
      repository: context.read<BooksRepository>(),
    );
    _reservationBloc = ReservationBloc(
      repository: context.read<ReservationsRepository>(),
    );
  }

  @override
  void dispose() {
    _dashboardCubit.close();
    _booksBloc.close();
    _reservationBloc.close();
    super.dispose();
  }

  List<NavigationItem> _getNavigationItems(String role) {
    final commonItems = [
      const NavigationItem(
        index: 0,
        selectedIcon: Icons.book,
        unselectedIcon: Icons.book_outlined,
        label: 'Books',
      ),
      const NavigationItem(
        index: 4,
        selectedIcon: Icons.settings,
        unselectedIcon: Icons.settings_outlined,
        label: 'Settings',
      ),
    ];

    final middleItems = role == 'admin'
        ? [
            const NavigationItem(
              index: 1,
              selectedIcon: Icons.dashboard,
              unselectedIcon: Icons.dashboard_outlined,
              label: 'Dashboard',
            ),
            const NavigationItem(
              index: 2,
              selectedIcon: Icons.people,
              unselectedIcon: Icons.people_outline,
              label: 'Users',
            ),
            const NavigationItem(
              index: 3,
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
              label: 'Bookings',
            ),
          ];

    return [...commonItems.take(1), ...middleItems, ...commonItems.skip(1)];
  }

  Widget _getScreenForIndex(int index, String role) {
    if (index == 0) {
      final navigationState = context.read<NavigationCubit>().state;
      if (navigationState.route == RouteNames.books) {
        final params = navigationState.params;
        final sortType = params != null ? SortType.values.firstWhere(
          (type) => type.toString() == params['sortType'],
          orElse: () => SortType.none,
        ) : null;

        return BlocProvider.value(
          value: _booksBloc,
          child: BooksScreen(
            key: const ValueKey('books_screen'),
            sortType: sortType,
          ),
        );
      }
      
      return BlocProvider.value(
        value: _booksBloc,
        child: const MainHomeScreen(key: ValueKey('main_home_screen')),
      );
    }

    final screens = {
      0: () => BlocProvider.value(
            value: _booksBloc,
            child: const MainHomeScreen(),
          ),
      1: () => role == 'admin'
          ? BlocProvider.value(
              value: _dashboardCubit,
              child: const DashboardScreen(),
            )
          : const FavoritesScreen(),
      2: () => role == 'admin'
          ? const UsersScreen()
          : BlocProvider.value(
              value: _reservationBloc..add(LoadReservations()),
              child: ReservationsScreen(
                reservationsService: _reservationsService,
                booksService: _firestoreService,
                usersService: _usersService,
              ),
            ),
      3: () => role == 'admin'
          ? BlocProvider.value(
              value: _reservationBloc..add(LoadReservations()),
              child: ReservationsScreen(
                reservationsService: _reservationsService,
                booksService: _firestoreService,
                usersService: _usersService,
              ),
            )
          : const SettingsScreen(),
      4: () => const SettingsScreen(),
    };

    return screens[index]?.call() ?? const SizedBox.shrink();
  }

  void _onItemSelected(int index) {
    setState(() => _selectedIndex = index);
    
    if (_cachedUserModel == null) return;
    
    if (_cachedUserModel!.role == 'admin') {
      switch (index) {
        case 0:
          context.read<NavigationCubit>().navigateToHome();
          break;
        case 1:
          context.read<NavigationCubit>().navigateToDashboard();
          break;
        case 2:
          context.read<NavigationCubit>().navigateToUsers();
          break;
        case 3:
          context.read<NavigationCubit>().navigateToBookings();
          break;
        case 4:
          context.read<NavigationCubit>().navigateToSettings();
          break;
      }
    } else {
      switch (index) {
        case 0:
          context.read<NavigationCubit>().navigateToHome();
          break;
        case 1:
          context.read<NavigationCubit>().navigateToFavorites();
          break;
        case 2:
          context.read<NavigationCubit>().navigateToBookings();
          break;
        case 3:
          context.read<NavigationCubit>().navigateToSettings();
          break;
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final mediaQuery = MediaQuery.of(context);
    _isSmallScreen = mediaQuery.size.width < 600;
    _isPortrait = mediaQuery.orientation == Orientation.portrait;
    
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthSuccess && _adminCheckStream == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _adminCheckStream = _usersService.getUserStream(authState.user.uid);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<NavigationCubit, NavigationState>(
      listener: (context, state) {
        switch (state.route) {
          case RouteNames.home:
            setState(() {
              _selectedIndex = 0;
              _booksBloc.add(const LoadBooksEvent());
            });
            break;
          case RouteNames.books:
            setState(() => _selectedIndex = 0);
            break;
          case RouteNames.dashboard:
            setState(() => _selectedIndex = 1);
            break;
          case RouteNames.users:
          case RouteNames.favorites:
            setState(() => _selectedIndex = 2);
            break;
          case RouteNames.bookings:
            setState(() => _selectedIndex = 3);
            break;
          case RouteNames.settings:
            setState(() => _selectedIndex = 4);
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

          if (_cachedUserModel != null) {
            return _buildHomeContentWithUser(_cachedUserModel!);
          }

          print('Fetching user data for userId: ${state.user.uid}');

          return FutureBuilder<DocumentSnapshot>(
            future: _usersService.getDocument('users', state.user.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const Center(child: Text('User data not found'));
              }

              final userData = snapshot.data!.data() as Map<String, dynamic>?;
              if (userData == null) {
                return const Center(child: Text('User data is null'));
              }

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

  Future<void> someMethod() async {
    final doc = await _firestoreService.getDocument('collection', 'id');
  }

  Widget _buildContent(NavigationState state) {
    if (state.params?['showBooks'] == true) {
      // Show BooksScreen with the navigation bar
      return BooksScreen(
        sortType: state.params?['sortType'] != null 
            ? SortType.values.firstWhere(
                (e) => e.toString() == state.params!['sortType']
              )
            : null,
      );
    }

    // Show default content
    return const MainHomeScreen();
  }
}