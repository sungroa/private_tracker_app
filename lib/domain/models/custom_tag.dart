import 'package:hive/hive.dart';

part 'custom_tag.g.dart';

@HiveType(typeId: 2)
class CustomTag extends HiveObject {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final bool isDefault;

  CustomTag({
    required this.name,
    this.isDefault = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'isDefault': isDefault,
    };
  }

  factory CustomTag.fromMap(Map<String, dynamic> map) {
    return CustomTag(
      name: map['name'],
      isDefault: map['isDefault'] ?? false,
    );
  }
}
