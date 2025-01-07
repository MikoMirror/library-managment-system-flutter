class Genre {
  final String id;
  final String name;
  final bool isDefault;
  
  const Genre({
    required this.id, 
    required this.name, 
    this.isDefault = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Genre &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
