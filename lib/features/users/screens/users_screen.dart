import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/users_bloc.dart';
import '../bloc/users_event.dart';
import '../bloc/users_state.dart';
import '../../../core/widgets/custom_app_bar.dart';

import '../widgets/users_table.dart';
import '../../../core/widgets/custom_search_bar.dart';
import '../../../core/navigation/cubit/navigation_cubit.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final _searchController = TextEditingController();
 

  @override
  void initState() {
    super.initState();
    // Load users when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UsersBloc>().add(LoadUsers());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
          title: Text(
            'Users',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        
        actions: [
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.4, // Adjust width as needed
            child: CustomSearchBar(
              hintText: 'Search users...',
              onChanged: (query) {
                if (query.isEmpty) {
                  context.read<UsersBloc>().add(LoadUsers());
                } else {
                  context.read<UsersBloc>().add(SearchUsers(query));
                }
              },
            ),
          ),
          const SizedBox(width: 8),
        ],
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
          debugPrint('Add user button pressed');
          context.read<NavigationCubit>().navigateToAddUser();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
} 