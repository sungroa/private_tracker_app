import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'custom_tag.g.dart';

@HiveType(typeId: 2)
class CustomTag {
  @HiveField(2, defaultValue: '')
  final String id;

  @HiveField(0)
  final String name;

  @HiveField(1)
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
