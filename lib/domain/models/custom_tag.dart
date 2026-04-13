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
       updatedAt = updatedAt ?? DateTime.now();

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
    return Object.hash(
      id,
      name,
      isDefault,
      updatedAt,
    );
  }
}
