import 'package:flutter/material.dart';
import '../services/library_settings_service.dart';

class AdvanceReservationSetting extends StatelessWidget {
  final LibrarySettingsService _settingsService = LibrarySettingsService();

  AdvanceReservationSetting({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 600;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: StreamBuilder<int>(
        stream: _settingsService.getMaxAdvanceReservationDays(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final currentDays = snapshot.data ?? 5;

          return Row(
            children: [
              // Left side - Text and Icon
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: Theme.of(context).primaryColor,
                      size: isDesktop ? 24 : 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Advance Reservation',
                            style: TextStyle(
                              fontSize: isDesktop ? 16 : 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'Maximum days in advance',
                            style: TextStyle(
                              fontSize: isDesktop ? 14 : 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Right side - Dropdown
              Container(
                constraints: BoxConstraints(
                  maxWidth: isDesktop ? 120 : 100,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: currentDays,
                    isExpanded: true,
                    items: List.generate(30, (index) => index + 1)
                        .map((days) => DropdownMenuItem(
                              value: days,
                              child: Text('$days days'),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        _settingsService.updateMaxAdvanceReservationDays(value);
                      }
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}