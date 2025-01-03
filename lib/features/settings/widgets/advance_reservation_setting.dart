import 'package:flutter/material.dart';
import '../services/library_settings_service.dart';

class AdvanceReservationSetting extends StatelessWidget {
  final LibrarySettingsService _settingsService = LibrarySettingsService();

  AdvanceReservationSetting({super.key});

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return StreamBuilder<int>(
      stream: _settingsService.getMaxAdvanceReservationDays(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final currentDays = snapshot.data ?? 5;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: isSmallScreen
              ? Column(
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Maximum days in advance',
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildInfoIcon(context),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Center(child: _buildDropdown(context, currentDays)),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Maximum days in advance',
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildInfoIcon(context),
                      ],
                    ),
                    _buildDropdown(context, currentDays),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildInfoIcon(BuildContext context) {
    return Tooltip(
      message: 'Maximum number of days in advance a user can make a reservation',
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6) ?? Colors.grey,
          ),
        ),
        child: Icon(
          Icons.info_outline,
          size: 16,
          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
        ),
      ),
    );
  }

  Widget _buildDropdown(BuildContext context, int currentDays) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 120),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: currentDays,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down),
          items: List.generate(30, (index) => index + 1)
              .map((days) => DropdownMenuItem(
                    value: days,
                    child: Text(
                      '$days days',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ))
              .toList(),
          onChanged: (value) {
            if (value != null) {
              _settingsService.updateMaxAdvanceReservationDays(value);
            }
          },
        ),
      ),
    );
  }
}