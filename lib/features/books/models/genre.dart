class Genre {
  final String id;
  final String name;
  final bool isDefault;

  const Genre({
    required this.id,
    required this.name,
    this.isDefault = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'isDefault': isDefault,
    };
  }

  static Genre fromMap(Map<String, dynamic> map, String id) {
    return Genre(
      id: id,
      name: map['name'] as String,
      isDefault: map['isDefault'] as bool? ?? false,
    );
  }
}