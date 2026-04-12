import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';

@immutable
class CustomTag {
  final String id;
  final String name;
  final bool isDefault;

  CustomTag({
    String? id,
    required this.name,
    this.isDefault = false,
  }) : id = id ?? const Uuid().v4();

  CustomTag copyWith({
    String? id,
    String? name,
    bool? isDefault,
  }) {
    return CustomTag(
      id: id ?? this.id,
      name: name ?? this.name,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'isDefault': isDefault,
    };
  }

  factory CustomTag.fromMap(Map<String, dynamic> map) {
    return CustomTag(
      id: map['id'],
      name: map['name'],
      isDefault: map['isDefault'] ?? false,
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
