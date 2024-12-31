import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/bloc/auth/auth_bloc.dart';
import '../../../features/users/models/user_model.dart';
import '../widgets/cache_management_widget.dart';
import '../../../core/theme/cubit/theme_cubit.dart';
import '../../../core/widgets/app_bar.dart';
import '../../../core/theme/cubit/test_mode_cubit.dart';

class SettingsScreen extends StatelessWidget {
  static final _firestore = FirebaseFirestore.instance;
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is! AuthSuccess) {
          return const Center(child: CircularProgressIndicator());
        }

        return Scaffold(
         appBar: UnifiedAppBar(
          isSimple: true,
          title: Text(
            'Settings',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: StreamBuilder<DocumentSnapshot>(
            stream: _firestore.collection('users')
                .doc(state.user.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const Center(child: Text('User data not found'));
              }

              final userData = snapshot.data!.data() as Map<String, dynamic>;
              final userModel = UserModel.fromMap(userData);
              final isAdmin = userModel.role == 'admin';

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'App Settings',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildThemeSettings(context, isAdmin),
                    const SizedBox(height: 16),
                    const CacheManagementWidget(),
                    const SizedBox(height: 32),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Logout'),
                              content: const Text('Are you sure you want to logout?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    context.read<AuthBloc>().add(LogoutRequested());
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                  child: const Text('Logout'),
                                ),
                              ],
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        icon: const Icon(Icons.logout),
                        label: const Text('Logout'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildThemeSettings(BuildContext context, bool isAdmin) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Theme',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            BlocBuilder<ThemeCubit, ThemeState>(
              builder: (context, state) {
                return SwitchListTile(
                  title: const Text('Dark Mode'),
                  value: state.isDarkMode,
                  onChanged: (_) {
                    context.read<ThemeCubit>().toggleTheme();
                  },
                );
              },
            ),
            if (isAdmin) ...[
              const Divider(),
              BlocBuilder<TestModeCubit, bool>(
                builder: (context, isTestMode) {
                  return SwitchListTile(
                    title: const Text('Test Mode'),
                    subtitle: const Text('Enable past dates selection in reservations'),
                    value: isTestMode,
                    onChanged: (_) {
                      context.read<TestModeCubit>().toggleTestMode();
                    },
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
} 