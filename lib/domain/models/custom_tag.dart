import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';

@immutable
class CustomTag {
  final String id;
  final String name;
  final bool isDefault;
  final DateTime updatedAt;

  CustomTag({
    String? id,
    required this.name,
    this.isDefault = false,
    DateTime? updatedAt,
  }) : id = id ?? const Uuid().v4(),
       updatedAt = updatedAt ?? DateTime(1970);

  CustomTag copyWith({
    String? id,
    String? name,
    bool? isDefault,
    DateTime? updatedAt,
  }) {
    return CustomTag(
      id: id ?? this.id,
      name: name ?? this.name,
      isDefault: isDefault ?? this.isDefault,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'isDefault': isDefault,
      'updatedAt': updatedAt.toUtc().toIso8601String(),
    };
  }

  factory CustomTag.fromMap(Map<String, dynamic> map) {
    return CustomTag(
      id: map['id'],
      name: map['name'],
      isDefault: map['isDefault'] ?? false,
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CustomTag &&
        other.id == id &&
        other.name == name &&
        other.isDefault == isDefault;
  }

  @override
  int get hashCode {
    return id.hashCode ^ name.hashCode ^ isDefault.hashCode;
  }
}
