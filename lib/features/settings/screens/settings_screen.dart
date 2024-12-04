import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../services/settings_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsService = SettingsService();

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is! AuthSuccess) {
          return const Center(child: CircularProgressIndicator());
        }

        final isAdmin = state.user.role == 'admin';

        return Scaffold(
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
                  StreamBuilder(
                    stream: settingsService.watchEmailSettings(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final hasEmailConfig = snapshot.hasData && snapshot.data!.exists;
                      final emailSettings = hasEmailConfig 
                          ? AppEmailSettings.fromMap(snapshot.data!.data() as Map<String, dynamic>)
                          : null;

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (hasEmailConfig) ...[
                                ListTile(
                                  leading: const Icon(Icons.email),
                                  title: const Text('Connected Email'),
                                  subtitle: Text(emailSettings!.email),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.logout),
                                    onPressed: () => settingsService.disconnectGoogleAccount(),
                                  ),
                                ),
                              ] else ...[
                                ListTile(
                                  leading: const Icon(Icons.email_outlined),
                                  title: const Text('Connect Email Account'),
                                  subtitle: const Text('Set up email notifications'),
                                  trailing: const Icon(Icons.arrow_forward_ios),
                                  onTap: () => settingsService.connectGoogleAccount(),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                ],
                // User Info Section
                const Text(
                  'Account Information',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.person),
                          title: const Text('Name'),
                          subtitle: Text(state.user.name),
                        ),
                        ListTile(
                          leading: const Icon(Icons.email),
                          title: const Text('Email'),
                          subtitle: Text(state.user.email),
                        ),
                        ListTile(
                          leading: const Icon(Icons.badge),
                          title: const Text('Library Number'),
                          subtitle: Text(state.user.libraryNumber),
                        ),
                        ListTile(
                          leading: const Icon(Icons.admin_panel_settings),
                          title: const Text('Role'),
                          subtitle: Text(state.user.role.toUpperCase()),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Logout Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ElevatedButton(
                    onPressed: () {
                      context.read<AuthBloc>().add(LogoutRequested());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Logout',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
} 