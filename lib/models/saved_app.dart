/// Model representing a saved app with its UI surfaces
class SavedApp {
  final String id;
  final String name;
  final List<Map<String, dynamic>> surfaces; // Serialized UiDefinition data
  final DateTime createdAt;
  final DateTime updatedAt;

  SavedApp({
    required this.id,
    required this.name,
    required this.surfaces,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from JSON map
  factory SavedApp.fromJson(Map<String, dynamic> json) {
    return SavedApp(
      id: json['id'] as String,
      name: json['name'] as String,
      surfaces: List<Map<String, dynamic>>.from(json['surfaces'] as List),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'surfaces': surfaces,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  SavedApp copyWith({
    String? id,
    String? name,
    List<Map<String, dynamic>>? surfaces,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SavedApp(
      id: id ?? this.id,
      name: name ?? this.name,
      surfaces: surfaces ?? this.surfaces,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

