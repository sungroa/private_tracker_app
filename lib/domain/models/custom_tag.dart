import 'package:uuid/uuid.dart';

class CustomTag {
  final String id;
  final String name;
  final bool isDefault;

  CustomTag({
    String? id,
    required this.name,
    this.isDefault = false,
  }) : id = id ?? const Uuid().v4();

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
}
