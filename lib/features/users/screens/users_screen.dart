import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/users_bloc.dart';
import '../bloc/users_event.dart';
import '../bloc/users_state.dart';
import '../../../core/widgets/app_bar.dart';

import '../widgets/users_table.dart';
import '../../../core/navigation/cubit/navigation_cubit.dart';
import '../screens/add_user_screen.dart';
import '../../../core/navigation/routes/route_names.dart';
import '../../../core/navigation/cubit/navigation_state.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UsersBloc>().add(LoadUsers());
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<NavigationCubit, NavigationState>(
      listener: (context, state) {
        debugPrint('Navigation state changed: ${state.route}');
        if (state.route == RouteNames.addUser) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddUserScreen(isAdmin: false),
            ),
          );
        }
      },
      child: Scaffold(
        appBar: UnifiedAppBar(
          title: const Text('Users'),
          searchHint: 'Search users...',
          onSearch: (query) {
            if (query.isEmpty) {
              context.read<UsersBloc>().add(LoadUsers());
            } else {
              context.read<UsersBloc>().add(SearchUsers(query));
            }
          },
        ),
        body: BlocBuilder<UsersBloc, UsersState>(
          builder: (context, state) {
            if (state is UsersLoading) {
              return const Center(child: CircularProgressIndicator());
            }

          if (state is UsersError) {
            return Center(child: Text('Error: ${state.message}'));
          }

          if (state is UsersLoaded) {
            if (state.users.isEmpty) {
              return const Center(
                child: Text(
                  'No users found',
                  style: TextStyle(fontSize: 18),
                ),
              );
            }

            return UsersTable(users: state.users);
          }

          return const Center(child: Text('No users available'));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddUserScreen(isAdmin: false),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    )
    );
  }
} 