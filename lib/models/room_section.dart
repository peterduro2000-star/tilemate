import 'dart:convert';

/// A rectangular section that makes up part of a room.
/// Rooms are built from one or more sections (for L-shapes, T-shapes, alcoves etc.)
class RoomSection {
  final String id;
  final String label;       // e.g. "Main area", "Alcove", "En-suite"
  final double length;      // in metres (normalised internally)
  final double width;       // in metres (normalised internally)
  final bool isSubtracted;  // true = this section is cut OUT of the total (e.g. a pillar or bathtub footprint)

  const RoomSection({
    required this.id,
    this.label = 'Section',
    required this.length,
    required this.width,
    this.isSubtracted = false,
  });

  /// Area of this section in m²
  double get area => length * width;

  /// Signed area: negative if subtracted
  double get signedArea => isSubtracted ? -area : area;

  RoomSection copyWith({
    String? id,
    String? label,
    double? length,
    double? width,
    bool? isSubtracted,
  }) {
    return RoomSection(
      id: id ?? this.id,
      label: label ?? this.label,
      length: length ?? this.length,
      width: width ?? this.width,
      isSubtracted: isSubtracted ?? this.isSubtracted,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'label': label,
        'length': length,
        'width': width,
        'isSubtracted': isSubtracted,
      };

  factory RoomSection.fromMap(Map<String, dynamic> map) => RoomSection(
        id: map['id'] as String,
        label: (map['label'] as String?) ?? 'Section',
        length: (map['length'] as num).toDouble(),
        width: (map['width'] as num).toDouble(),
        isSubtracted: (map['isSubtracted'] as bool?) ?? false,
      );

  String toJson() => json.encode(toMap());

  factory RoomSection.fromJson(String source) =>
      RoomSection.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      'RoomSection(id: $id, label: $label, ${length}m × ${width}m, subtracted: $isSubtracted)';
}