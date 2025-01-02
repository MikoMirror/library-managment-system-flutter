import 'package:flutter/material.dart';
import '../services/library_settings_service.dart';

class AdvanceReservationSetting extends StatelessWidget {
  final LibrarySettingsService _settingsService = LibrarySettingsService();

  AdvanceReservationSetting({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Advance Reservation',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Maximum number of days users can reserve in advance',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<int>(
              stream: _settingsService.getMaxAdvanceReservationDays(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final currentDays = snapshot.data ?? 5;

                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: currentDays.toDouble(),
                            min: 1,
                            max: 30,
                            divisions: 29,
                            label: '$currentDays days',
                            onChanged: (value) {
                              _settingsService.updateMaxAdvanceReservationDays(value.round());
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          width: 60,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$currentDays',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Maximum ${currentDays} days in advance',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
} 