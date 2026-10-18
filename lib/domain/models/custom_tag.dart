import 'package:meta/meta.dart';

/// Represents a user-defined category for health events.
///
/// 💼 **Domain Context**: This model allows users to personalize the logging
/// experience by adding categories that are not included by default (e.g., 'Cramp', 'Brain Fog').
@immutable
class CustomTag {
  /// Canonical constructor for [CustomTag].
  const CustomTag({
    required this.id,
    required this.name,
    this.isDefault = false,
    required this.updatedAt,
  });

  /// Unique identifier for the tag.
  final String id;

  /// The user-facing label for this tag.
  final String name;

  /// Whether this is a system-provided tag that cannot be easily deleted.
  final bool isDefault;

  /// The last time this tag metadata was modified.
  final DateTime updatedAt;

  CustomTag copyWith({String? id, String? name, bool? isDefault, DateTime? updatedAt}) {
    return CustomTag(
      id: id ?? this.id,
      name: name ?? this.name,
      isDefault: isDefault ?? this.isDefault,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CustomTag &&
        other.id == id &&
        other.name == name &&
        other.isDefault == isDefault &&
        other.updatedAt.isAtSameMomentAs(updatedAt);
  }

  @override
  int get hashCode {
    return Object.hash(id, name, isDefault, updatedAt);
  }
}
