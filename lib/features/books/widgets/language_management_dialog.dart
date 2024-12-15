import 'package:flutter/material.dart';
import '../../../core/constants/language_constants.dart';
import '../../../core/theme/app_theme.dart';

class LanguageManagementDialog extends StatefulWidget {
  const LanguageManagementDialog({super.key});

  @override
  State<LanguageManagementDialog> createState() => _LanguageManagementDialogState();
}

class _LanguageManagementDialogState extends State<LanguageManagementDialog> {
  late List<Language> _activeLanguages;
  late List<Language> _availableLanguages;
  
  @override
  void initState() {
    super.initState();
    _initializeLists();
  }

  void _initializeLists() {
    _activeLanguages = LanguageConstants.getActiveLanguages();
    _availableLanguages = LanguageConstants.getAllLanguages()
        .where((lang) => !_activeLanguages.contains(lang))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? AppTheme.dark : AppTheme.light;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 500,
          maxHeight: 600,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Manage Languages',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Active Languages',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Card(
                  child: ListView.builder(
                    itemCount: _activeLanguages.length,
                    itemBuilder: (context, index) {
                      final language = _activeLanguages[index];
                      return ListTile(
                        title: Text('${language.name} (${language.code})'),
                        trailing: IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          color: colors.error,
                          onPressed: () => _removeLanguage(language),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Available Languages',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Card(
                  child: ListView.builder(
                    itemCount: _availableLanguages.length,
                    itemBuilder: (context, index) {
                      final language = _availableLanguages[index];
                      return ListTile(
                        title: Text('${language.name} (${language.code})'),
                        trailing: IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          color: colors.primary,
                          onPressed: () => _addLanguage(language),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _saveChanges,
                    child: const Text('Save Changes'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _removeLanguage(Language language) {
    if (_activeLanguages.length > 1) {
      setState(() {
        _activeLanguages.remove(language);
        _availableLanguages.add(language);
        _availableLanguages.sort((a, b) => a.name.compareTo(b.name));
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('At least one language must remain active'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _addLanguage(Language language) {
    setState(() {
      _availableLanguages.remove(language);
      _activeLanguages.add(language);
      _activeLanguages.sort((a, b) => a.name.compareTo(b.name));
    });
  }

  void _saveChanges() {
    LanguageConstants.updateActiveLanguages(_activeLanguages);
    Navigator.of(context).pop();
  }
} 