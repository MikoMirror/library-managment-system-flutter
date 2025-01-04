class Language {
  final String code;
  final String name;
  
  const Language({required this.code, required this.name});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Language &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;
}

class LanguageConstants {
  static const List<Language> _allLanguages = [
    Language(code: 'en', name: 'English'),
    Language(code: 'zh', name: 'Chinese'),
    Language(code: 'es', name: 'Spanish'),
    Language(code: 'fr', name: 'French'),
    Language(code: 'de', name: 'German'),
    Language(code: 'ja', name: 'Japanese'),
    Language(code: 'ru', name: 'Russian'),
    Language(code: 'it', name: 'Italian'),
    Language(code: 'ar', name: 'Arabic'),
    Language(code: 'pt', name: 'Portuguese'),
    Language(code: 'pt-BR', name: 'Portuguese (Brazil)'),
    Language(code: 'hi', name: 'Hindi'),
    Language(code: 'ko', name: 'Korean'),
    Language(code: 'pl', name: 'Polish'),
    Language(code: 'tr', name: 'Turkish'),
    Language(code: 'nl', name: 'Dutch'),
    Language(code: 'sv', name: 'Swedish'),
    Language(code: 'da', name: 'Danish'),
    Language(code: 'fi', name: 'Finnish'),
    Language(code: 'no', name: 'Norwegian'),
    Language(code: 'el', name: 'Greek'),
    Language(code: 'he', name: 'Hebrew'),
    Language(code: 'th', name: 'Thai'),
    Language(code: 'vi', name: 'Vietnamese'),
    Language(code: 'cs', name: 'Czech'),
    Language(code: 'uk', name: 'Ukrainian'),
    Language(code: 'hu', name: 'Hungarian'),
    Language(code: 'ro', name: 'Romanian'),
    Language(code: 'id', name: 'Indonesian'),
    Language(code: 'ms', name: 'Malay'),
  ];

  static List<Language> _activeLanguages = [
    const Language(code: 'en', name: 'English'),
    const Language(code: 'pl', name: 'Polish'),
  ];

  static const String defaultLanguage = 'en';

  static List<Language> getAllLanguages() {
    final languages = List<Language>.from(_allLanguages);
    languages.sort((a, b) => a.name.compareTo(b.name));
    return languages;
  }
  
  static List<Language> getActiveLanguages() {
    final languages = List<Language>.from(_activeLanguages);
    languages.sort((a, b) => a.name.compareTo(b.name));
    return languages;
  }

  static void updateActiveLanguages(List<Language> languages) {
    _activeLanguages = languages;
  }

  static String getLanguageName(String code) {
    return _allLanguages
        .firstWhere(
          (lang) => lang.code == code, 
          orElse: () => const Language(code: defaultLanguage, name: 'English')
        )
        .name;
  }

  static bool isValidLanguage(String code) {
    return _activeLanguages.any((lang) => lang.code == code);
  }
} 