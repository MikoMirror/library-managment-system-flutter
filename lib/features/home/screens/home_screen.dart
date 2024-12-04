import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../screens/login_screen.dart';
import '../screens/users_screen.dart';
import '../widgets/custom_navigation_bar.dart';
import '../screens/settings_screen.dart';
import '../widgets/add_book_dialog.dart';
import '../screens/books_screen.dart';
import 'favorites_screen.dart';
import 'my_bookings_screen.dart';
import 'bookings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  List<NavigationItem> _getNavigationItems(String role) {
    if (role == 'admin') {
      return [
        const NavigationItem(
          index: 0,
          selectedIcon: Icons.book,
          unselectedIcon: Icons.book_outlined,
          label: 'Books',
        ),
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
        const NavigationItem(
          index: 3,
          selectedIcon: Icons.settings,
          unselectedIcon: Icons.settings_outlined,
          label: 'Settings',
        ),
      ];
    } else {
      return [
        const NavigationItem(
          index: 0,
          selectedIcon: Icons.book,
          unselectedIcon: Icons.book_outlined,
          label: 'Books',
        ),
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
        const NavigationItem(
          index: 3,
          selectedIcon: Icons.settings,
          unselectedIcon: Icons.settings_outlined,
          label: 'Settings',
        ),
      ];
    }
  }

  Widget _getScreenForIndex(int index, String role) {
    if (role == 'admin') {
      switch (index) {
        case 0:
          return const BooksScreen();
        case 1:
          return const UsersScreen();
        case 2:
          return const BookingsScreen();
        case 3:
          return const SettingsScreen();
        default:
          return const Center(child: Text('Unknown Screen'));
      }
    } else {
      switch (index) {
        case 0:
          return const BooksScreen();
        case 1:
          return const FavoritesScreen();
        case 2:
          return const MyBookingsScreen();
        case 3:
          return const SettingsScreen();
        default:
          return const Center(child: Text('Unknown Screen'));
      }
    }
  }

  void _showAddBookDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const AddBookDialog();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthSuccess) {
          final userRole = state.user.role;
          final navigationItems = _getNavigationItems(userRole);

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
            body: LayoutBuilder(
              builder: (context, constraints) {
                return Row(
                  children: [
                    if (constraints.maxWidth >= 600)
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
                          onItemSelected: (index) => setState(() => _selectedIndex = index),
                          isHorizontal: true,
                          items: navigationItems,
                        ),
                      ),
                    Expanded(
                      child: _getScreenForIndex(_selectedIndex, userRole),
                    ),
                  ],
                );
              },
            ),
            bottomNavigationBar: LayoutBuilder(
              builder: (context, constraints) {
                final isHorizontal = constraints.maxWidth >= 600;
                return isHorizontal
                    ? const SizedBox.shrink()
                    : CustomNavigationBar(
                        selectedIndex: _selectedIndex,
                        onItemSelected: (index) => setState(() => _selectedIndex = index),
                        isHorizontal: false,
                        items: navigationItems,
                      );
              },
            ),
          );
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}