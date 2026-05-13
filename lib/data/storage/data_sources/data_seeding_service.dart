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

  static const String _tagNamespace = 'a84d4b1a-8e2b-4b1a-9a2b-4b1a8e2b4b1a';

  /// Ensures default tags exist with deterministic IDs and cleans up duplicates.
  ///
  /// This implementation solves the "multi-device duplication" bug by transitioning
  /// from random UUIDs to deterministic UUID v5 IDs based on the tag name.
  Future<void> seedDefaultTags(Box<CustomTagDto> tagBox) async {
    const uuid = Uuid();
    final Map<String, CustomTagDto> tagsToPut = {};
    final Set<String> defaultIds = {};

    // 1. Ensure all default tags exist with deterministic IDs
    for (var name in _defaultTags) {
      final deterministicId = uuid.v5(_tagNamespace, name);
      defaultIds.add(deterministicId);
      
      if (!tagBox.containsKey(deterministicId)) {
        final tag = CustomTag(
          id: deterministicId,
          name: name,
          isDefault: true,
          updatedAt: DateTime.now(),
        );
        tagsToPut[deterministicId] = ModelMapper.customTagToDto(tag);
      }
    }

    if (tagsToPut.isNotEmpty) {
      await tagBox.putAll(tagsToPut);
    }

    // 2. Cleanup: Remove "orphan" default tags (same name, wrong ID)
    // We identify them as tags marked 'isDefault' whose ID is not in the deterministic set.
    final keysToDelete = <String>[];
    for (var key in tagBox.keys) {
      final dto = tagBox.get(key);
      if (dto != null && dto.isDefault) {
        if (!defaultIds.contains(key.toString())) {
          keysToDelete.add(key.toString());
        }
      }
    }

    if (keysToDelete.isNotEmpty) {
      await tagBox.deleteAll(keysToDelete);
    }
  }
}
