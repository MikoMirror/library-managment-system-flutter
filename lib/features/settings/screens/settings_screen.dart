import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/bloc/auth/auth_bloc.dart';
import '../../../core/services/settings/settings_service.dart';
import '../../../features/users/models/user_model.dart';

class SettingsScreen extends StatelessWidget {
  static final _firestore = FirebaseFirestore.instance;
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsService = SettingsService();

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is! AuthSuccess) {
          return const Center(child: CircularProgressIndicator());
        }

        return FutureBuilder<DocumentSnapshot>(
          future: _firestore.collection('users').doc(state.user.uid).get(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final userData = snapshot.data!.data() as Map<String, dynamic>;
            final userModel = UserModel.fromMap(userData);
            final isAdmin = userModel.role == 'admin';

            return Scaffold(
              appBar: AppBar(
                title: const Text('Settings'),
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isAdmin) ...[
                      const Text(
                        'Email Settings',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      FutureBuilder<DocumentSnapshot>(
                        future: settingsService.getEmailSettings(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          }

                          if (!snapshot.hasData || !snapshot.data!.exists) {
                            return const Text('No email settings found');
                          }

                          final data = snapshot.data!.data() as Map<String, dynamic>;
                          return _buildEmailSettings(context, data, settingsService);
                        },
                      ),
                    ],
                    const SizedBox(height: 24),
                    const Text(
                      'App Settings',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FutureBuilder<DocumentSnapshot>(
                      future: settingsService.getAppSettings(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        }

                        if (!snapshot.hasData || !snapshot.data!.exists) {
                          return const Text('No app settings found');
                        }

                        final data = snapshot.data!.data() as Map<String, dynamic>;
                        return _buildAppSettings(context, data, settingsService);
                      },
                    ),
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
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmailSettings(
    BuildContext context,
    Map<String, dynamic> settings,
    SettingsService service,
  ) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('Email settings coming soon'),
      ),
    );
  }

  Widget _buildAppSettings(
    BuildContext context,
    Map<String, dynamic> settings,
    SettingsService service,
  ) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('App settings coming soon'),
      ),
    );
  }
} 