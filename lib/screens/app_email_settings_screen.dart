import 'package:flutter/material.dart';
import '../services/settings_service.dart';

class AppEmailSettingsScreen extends StatefulWidget {
  const AppEmailSettingsScreen({super.key});

  @override
  State<AppEmailSettingsScreen> createState() => _AppEmailSettingsScreenState();
}

class _AppEmailSettingsScreenState extends State<AppEmailSettingsScreen> {
  final _settingsService = SettingsService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Email Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder(
          stream: _settingsService.watchEmailSettings(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final hasEmailConfig = snapshot.hasData && snapshot.data!.exists;
            final emailSettings = hasEmailConfig 
                ? AppEmailSettings.fromMap(snapshot.data!.data() as Map<String, dynamic>)
                : null;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Email Configuration',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                if (hasEmailConfig) ...[
                  _buildInfoCard(
                    title: 'Connected Email',
                    value: emailSettings!.email,
                    icon: Icons.email,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    title: 'Display Name',
                    value: emailSettings.displayName,
                    icon: Icons.person,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _disconnectAccount,
                    icon: const Icon(Icons.logout, color: Colors.red),
                    label: const Text(
                      'Disconnect Account',
                      style: TextStyle(color: Colors.red),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.withOpacity(0.1),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                ] else ...[
                  const Text(
                    'No email account connected. Connect a Google account to enable email notifications.',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _connectAccount,
                    icon: const Icon(Icons.login, color: Colors.blue),
                    label: const Text(
                      'Connect Account',
                      style: TextStyle(color: Colors.blue),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.withOpacity(0.1),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: Colors.grey),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 16),
            Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _connectAccount() async {
    setState(() {
      _isLoading = true;
    });

    final connected = await _settingsService.connectGoogleAccount();

    if (connected) {
      setState(() {
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to connect Google account.'),
        ),
      );
    }
  }

  Future<void> _disconnectAccount() async {
    setState(() {
      _isLoading = true;
    });

    await _settingsService.disconnectGoogleAccount();

    setState(() {
      _isLoading = false;
    });
  }
} 