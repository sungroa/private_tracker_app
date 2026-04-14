import 'package:uuid/uuid.dart';
import '../hive_dtos.dart';
import '../../../domain/models/custom_tag.dart';
import '../model_mapper.dart';
import 'package:hive/hive.dart';

/// Service responsible for populating the database with default data on first run.
///
/// Decouples business rules (like what tags are default) from the persistence manager.
class DataSeedingService {
  static const List<String> _defaultTags = [
    'Cramps',
    'Bloating',
    'Acne',
    'Headache',
    'Mood Swings',
    'Fatigue',
  ];

  /// Checks if the provided box is empty and populates it with default tags if so.
  Future<void> seedDefaultTags(Box<CustomTagDto> tagBox) async {
    if (tagBox.isEmpty) {
      final Map<String, CustomTagDto> tagsToPut = {};
      const uuid = Uuid();
      for (var name in _defaultTags) {
        final tag = CustomTag(
          id: uuid.v4(),
          name: name,
          isDefault: true,
          updatedAt: DateTime.now(),
        );
        tagsToPut[tag.id] = ModelMapper.customTagToDto(tag);
      }
      await tagBox.putAll(tagsToPut);
    }
  }
}
